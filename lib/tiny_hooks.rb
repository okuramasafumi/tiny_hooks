# frozen_string_literal: true

require_relative 'tiny_hooks/version'

# TinyHooks is the gem to easily define hooks.
# `extend` this module and now you can define hooks with `define_hook` method.
# See the test file for more detailed usage.
module TinyHooks
  class Error < StandardError; end

  class PrivateError < Error; end

  class TargetError < Error; end

  HALTING = Object.new.freeze
  private_constant :HALTING
  UNDEFINED_TARGETS = [].freeze
  private_constant :UNDEFINED_TARGETS

  # @api private
  def self.included(base)
    base.class_eval do
      @_originals = {}
      @_class_originals = {}
      @_targets = UNDEFINED_TARGETS
      @_public_only = false
    end
    base.extend ClassMethods
  end

  # @api private
  def self.with_halting(terminator, *args, **kwargs, &block)
    hook_result = nil
    abort_result = catch :abort do
      hook_result = instance_exec(*args, **kwargs, &block)
      true
    end
    return HALTING if abort_result.nil? && terminator == :abort
    return HALTING if hook_result == false && terminator == :return_false

    hook_result
  end

  # Class methods
  module ClassMethods
    # Define hook with kind and target method
    #
    # @param [Symbol, String] kind the kind of the hook, possible values are: :before, :after and :around
    # @param [Symbol, String] target the name of the targeted method
    # @param hook_method_name [Symbol, String] the name of a method which should be called as a hook
    # @param [Symbol] terminator choice for terminating execution, default is throwing abort symbol
    # @param [Symbol] if condition to determine if it should define callback. Block is evaluated in context of self
    # @param class_method [Boolean] treat target as class method
    def define_hook(kind, target, hook_method_name = nil, terminator: :abort, if: nil, class_method: false, &block) # rubocop:disable Naming/MethodParameterName
      raise ArgumentError, 'You must provide a block or hook_method_name' unless block || hook_method_name
      raise ArgumentError, 'Terminator must be one of the following: :abort or :return_false' unless %i[abort return_false].include? terminator.to_sym
      raise TinyHooks::TargetError, "Hook for #{target} is not allowed" if @_targets != UNDEFINED_TARGETS && !@_targets.include?(target)

      if class_method
        is_private = private_methods.include?(target.to_sym)

        begin
          original_method = @_public_only ? public_method(target) : method(target)
        rescue NameError => e
          raise unless e.message.include?('private')

          raise TinyHooks::PrivateError, "Public only mode is on and hooks for private methods (#{target} for this time) are not available."
        end
        @_class_originals[target.to_sym] = original_method unless @_class_originals[target.to_sym]

        block ||= -> { __send__(hook_method_name) }
        body = method_body(kind, original_method, terminator, binding.local_variable_get(:if), &block)
        singleton_class.class_eval do
          undef_method(target)
          define_method(target, &body)
          private target if is_private
        end
      else # instance method
        is_private = private_instance_methods.include?(target.to_sym)

        begin
          original_method = @_public_only ? public_instance_method(target) : instance_method(target)
        rescue NameError => e
          raise unless e.message.include?('private')

          raise TinyHooks::PrivateError, "Public only mode is on and hooks for private methods (#{target} for this time) are not available."
        end
        @_originals[target.to_sym] = original_method unless @_originals[target.to_sym]

        block ||= -> { __send__(hook_method_name) }

        undef_method(target)
        define_method(target, &method_body(kind, original_method, terminator, binding.local_variable_get(:if), &block))
        private target if is_private
      end
    end

    # Restore original method
    #
    # @param [Symbol, String] target
    # @param class_method [Boolean] treat target as class method
    def restore_original(target, class_method: false)
      if class_method
        original_method = @_class_originals[target.to_sym] || method(target)
        singleton_class.class_eval do
          undef_method(target)
          define_method(target, original_method)
        end
      else
        original_method = @_originals[target.to_sym] || instance_method(target)
        undef_method(target)
        define_method(target, original_method)
      end
    end

    # Defines target for hooks
    # @param include_pattern [Regexp]
    # @param exclude_pattern [Regexp]
    def target!(include_pattern: nil, exclude_pattern: nil)
      raise ArgumentError if include_pattern.nil? && exclude_pattern.nil?

      candidates = @_public_only ? instance_methods : instance_methods + private_instance_methods
      candidates += @public_only ? methods : methods + private_methods
      @_targets = if include_pattern && exclude_pattern
                    targets = candidates.grep(include_pattern)
                    targets.grep_v(exclude_pattern)
                  elsif include_pattern
                    candidates.grep(include_pattern)
                  else
                    candidates.grep_v(exclude_pattern)
                  end
    end

    # Enable public only mode
    def public_only!
      @_public_only = true
    end

    # Disable public only mode
    def include_private!
      @_public_only = false
    end

    private

    def method_body(kind, original_method, terminator, if_proc, &block)
      case kind.to_sym
      when :before then _before(original_method, terminator: terminator, if_proc: if_proc, &block)
      when :after  then _after(original_method, if_proc: if_proc, &block)
      when :around then _around(original_method, if_proc: if_proc, &block)
      else
        raise Error, "#{kind} is not supported."
      end
    end

    def _before(original_method, terminator:, if_proc:, &block)
      if RUBY_VERSION >= '2.7'
        proc do |*args, **kwargs, &blk|
          if if_proc.nil? || instance_exec(&if_proc) != false
            hook_result = nil
            abort_result = catch :abort do
              hook_result = instance_exec(*args, **kwargs, &block)
              true
            end
            return if abort_result.nil? && terminator == :abort
            return if hook_result == false && terminator == :return_false
          end

          original_method.is_a?(UnboundMethod) ? original_method.bind_call(self, *args, **kwargs, &blk) : original_method.call(*args, **kwargs, &blk)
        end
      else
        proc do |*args, &blk|
          if if_proc.nil? || instance_exec(&if_proc) != false
            hook_result = nil
            abort_result = catch :abort do
              hook_result = instance_exec(*args, &block)
              true
            end
            return if abort_result.nil? && terminator == :abort
            return if hook_result == false && terminator == :return_false
          end

          original_method = original_method.bind(self) if original_method.is_a?(UnboundMethod)
          original_method.call(*args, &blk)
        end
      end
    end

    def _after(original_method, if_proc:, &block)
      if RUBY_VERSION >= '2.7'
        proc do |*args, **kwargs, &blk|
          original_method.is_a?(UnboundMethod) ? original_method.bind_call(self, *args, **kwargs, &blk) : original_method.call(*args, **kwargs, &blk)
          instance_exec(*args, **kwargs, &block) if if_proc.nil? || instance_exec(&if_proc) != false
        end
      else
        proc do |*args, &blk|
          original_method = original_method.bind(self) if original_method.is_a?(UnboundMethod)
          original_method.call(*args, &blk)
          instance_exec(*args, &block) if if_proc.nil? || instance_exec(&if_proc) != false
        end
      end
    end

    def _around(original_method, if_proc:, &block)
      if RUBY_VERSION >= '2.7'
        proc do |*args, **kwargs, &blk|
          wrapper = lambda do
            original_method.is_a?(UnboundMethod) ? original_method.bind_call(self, *args, **kwargs, &blk) : original_method.call(*args, **kwargs, &blk)
          end
          instance_exec(wrapper, *args, **kwargs, &block) if if_proc.nil? || instance_exec(&if_proc) != false
        end
      else
        proc do |*args, &blk|
          wrapper = lambda do
            original_method = original_method.bind(self) if original_method.is_a?(UnboundMethod)
            original_method.call(*args, &blk)
          end
          instance_exec(wrapper, *args, &block) if if_proc.nil? || instance_exec(&if_proc) != false
        end
      end
    end

    def inherited(subclass)
      super
      subclass.instance_variable_set(:@_originals, instance_variable_get(:@_originals).clone)
      subclass.instance_variable_set(:@_class_originals, instance_variable_get(:@_class_originals).clone)
      subclass.instance_variable_set(:@_targets, instance_variable_get(:@_targets).clone)
      subclass.instance_variable_set(:@_public_only, instance_variable_get(:@_public_only).clone)
    end
  end
end
