# frozen_string_literal: true

require_relative 'tiny_hooks/version'

# TinyHooks is the gem to easily define hooks.
# `extend` this module and now you can define hooks with `define_hook` method.
# See the test file for more detailed usage.
module TinyHooks
  class Error < StandardError; end

  HALTING = Object.new.freeze
  private_constant :HALTING

  # @api private
  def self.extended(mod)
    mod.class_eval { @@_originals ||= {} }
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

  # Define hook with kind and target method
  #
  # @param [Symbol, String] kind the kind of the hook, possible values are: :before, :after and :around
  # @param [Symbol, String] target the name of the targeted method
  # @param [Symbol] terminator choice for terminating execution, default is throwing abort symbol
  def define_hook(kind, target, terminator: :abort, &block)
    raise ArgumentError, 'You must provide a block' unless block
    raise ArgumentError, 'terminator must be one of the following: :abort or :return_false' unless %i[abort return_false].include? terminator.to_sym

    original_method = instance_method(target)
    @@_originals[target.to_sym] = original_method unless @@_originals[target.to_sym]

    body = case kind.to_sym
           when :before then _before(original_method, terminator: terminator, &block)
           when :after  then _after(original_method, &block)
           when :around then _around(original_method, &block)
           else
             raise Error, "#{kind} is not supported."
           end
    undef_method(target)
    define_method(target, &body)
  end

  module_function :define_hook

  # Restore original method
  #
  # @param [Symbol, String] target
  def restore_original(target)
    original_method = @@_originals[target.to_sym] || instance_method(target)

    undef_method(target)
    define_method(target, original_method)
  end

  private

  def _before(original_method, terminator:, &block)
    if RUBY_VERSION >= '2.7'
      proc do |*args, **kwargs, &blk|
        result = TinyHooks.with_halting(terminator, *args, **kwargs, &block)
        return if result == HALTING

        original_method.bind_call(self, *args, **kwargs, &blk)
      end
    else
      proc do |*args, &blk|
        result = TinyHooks.with_halting(terminator, *args, &block)
        return if result == HALTING

        original_method.bind(self).call(*args, &blk)
      end
    end
  end

  def _after(original_method, &block)
    if RUBY_VERSION >= '2.7'
      proc do |*args, **kwargs, &blk|
        original_method.bind_call(self, *args, **kwargs, &blk)
        instance_exec(*args, **kwargs, &block)
      end
    else
      proc do |*args, &blk|
        original_method.bind(self).call(*args, &blk)
        instance_exec(*args, &block)
      end
    end
  end

  def _around(original_method, &block)
    if RUBY_VERSION >= '2.7'
      proc do |*args, **kwargs, &blk|
        wrapper = -> { original_method.bind_call(self, *args, **kwargs, &blk) }
        instance_exec(wrapper, *args, **kwargs, &block)
      end
    else
      proc do |*args, &blk|
        wrapper = -> { original_method.bind(self).call(*args, &blk) }
        instance_exec(wrapper, *args, &block)
      end
    end
  end
end
