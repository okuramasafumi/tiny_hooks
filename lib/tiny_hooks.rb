# frozen_string_literal: true

require_relative 'tiny_hooks/version'

# TinyHooks is the gem to easily define hooks.
# `extend` this module and now you can define hooks with `define_hook` method.
# See the test file for more detailed usage.
module TinyHooks
  class Error < StandardError; end

  # rubocop:disable Metrics/MethodLength
  # Define hook with kind and target method
  #
  # @param [Symbol, String] kind the kind of the hook, possible values are: :before, :after and :around
  # @param [Symbol, String] target the name of the targeted method
  def define_hook(kind, target, &block)
    original_method = instance_method(target)
    body = case kind.to_sym
           when :before
             proc do |*args, **kwargs, &blk|
               instance_exec(*args, **kwargs, &block)
               original_method.bind_call(self, *args, **kwargs, &blk)
             end
           when :after
             proc do |*args, **kwargs, &blk|
               original_method.bind_call(self, *args, **kwargs, &blk)
               instance_exec(*args, **kwargs, &block)
             end
           when :around
             proc do |*args, **kwargs, &blk|
               wrapper = -> { original_method.bind_call(self, *args, **kwargs, &blk) }
               instance_exec(wrapper, *args, **kwargs, &block)
             end
           else
             raise Error, "#{kind} is not supported."
           end
    undef_method(target)
    define_method(target, &body)
  end
  # rubocop:enable Metrics/MethodLength

  module_function :define_hook
end
