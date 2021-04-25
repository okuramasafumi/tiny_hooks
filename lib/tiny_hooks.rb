# frozen_string_literal: true

require_relative 'tiny_hooks/version'

# TinyHooks is the gem to easily define hooks.
# `extend` this module and now you can define hooks with `define_hook` method.
# See the test file for more detailed usage.
module TinyHooks
  class Error < StandardError; end

  # @api private
  def self.extended(mod)
    mod.class_eval { @@_originals ||= {} }
  end

  # Define hook with kind and target method
  #
  # @param [Symbol, String] kind the kind of the hook, possible values are: :before, :after and :around
  # @param [Symbol, String] target the name of the targeted method
  def define_hook(kind, target, &block)
    raise ArgumentError, 'You must provide a block' unless block

    original_method = instance_method(target)
    @@_originals[target.to_sym] = original_method unless @@_originals[target.to_sym]

    body = case kind.to_sym
           when :before
             _before(original_method, &block)
           when :after
             _after(original_method, &block)
           when :around
             _around(original_method, &block)
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

  def _before(original_method, &block)
    if RUBY_VERSION >= '2.7'
      proc do |*args, **kwargs, &blk|
        instance_exec(*args, **kwargs, &block)
        original_method.bind_call(self, *args, **kwargs, &blk)
      end
    else
      proc do |*args, &blk|
        instance_exec(*args, &block)
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
