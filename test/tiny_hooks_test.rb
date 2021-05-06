# frozen_string_literal: true

require 'test_helper'

class TinyHooksTest < Minitest::Test
  class C
    include TinyHooks

    def a
      puts 'a'
    end

    private

    def b
      puts 'b'
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::TinyHooks::VERSION
  end

  class C1 < C
    define_hook :before, :a do
      puts 'before a'
    end
  end

  class C2 < C
    define_hook :after, :a do
      puts 'after a'
    end
  end

  class C3 < C
    define_hook :around, :a do |a|
      puts 'before a'
      a.call
      puts 'after a'
    end
  end

  class C4 < C
    define_hook :before, :a do
      puts 'before a 1'
    end

    define_hook :before, :a do
      puts 'before a 2'
    end
  end

  class C5 < C
    define_hook :after, :a do
      puts 'after a 1'
    end

    define_hook :after, :a do
      puts 'after a 2'
    end
  end

  class C6 < C
    define_hook :around, :a do |a|
      puts 'before a 1'
      a.call
      puts 'after a 1'
    end

    define_hook :around, :a do |a|
      puts 'before a 2'
      a.call
      puts 'after a 2'
    end
  end

  class C1Restore < C1
    restore_original :a
  end

  class C7 < C
    def b; end

    restore_original :b
  end

  class C8 < C
    define_hook :before, :a do
      throw :abort
    end
  end

  class C9 < C
    define_hook :before, :a do
      nil
    end
  end

  class C10 < C
    define_hook :before, :a, terminator: :return_false do
      false
    end
  end

  class C11 < C
    define_hook :before, :a, terminator: :return_false do
      nil
    end
  end

  class C12 < C
    define_hook :around, :a do |original|
      next
      original.call # rubocop:disable Lint/UnreachableCode
    end
  end

  class C13 < C
    define_hook :before, :b do
      puts 'before b'
    end
  end

  class C14 < C
    public_only!
    include_private!
    define_hook :before, :b do
      puts 'before b'
    end
  end

  def test_it_defines_before_hook
    c = C1.new
    assert_output("before a\na\n") { c.a }
  end

  def test_it_defines_after_hook
    c = C2.new
    assert_output("a\nafter a\n") { c.a }
  end

  def test_it_defines_around_hook
    c = C3.new
    assert_output("before a\na\nafter a\n") { c.a }
  end

  def test_it_defines_before_hook_twice
    c = C4.new
    assert_output("before a 2\nbefore a 1\na\n") { c.a }
  end

  def test_it_defines_after_hook_twice
    c = C5.new
    assert_output("a\nafter a 1\nafter a 2\n") { c.a }
  end

  def test_it_defines_around_hook_twice
    c = C6.new
    assert_output("before a 2\nbefore a 1\na\nafter a 1\nafter a 2\n") { c.a }
  end

  def test_it_restores_original
    c = C1Restore.new
    assert_output("a\n") { c.a }
  end

  def test_it_does_nothing_when_restoring_methods_without_hooks
    C7.new
    assert true # No error
  end

  def test_it_raises_error_when_restoring_missing_methods
    definition = <<~DEFINITION
      class CError < C
        restore_original :missing
      end
    DEFINITION
    assert_raises(NameError) { eval(definition) }
  end

  def test_it_stops_execution_when_hooks_throw_abort
    c = C8.new
    assert_output('') { c.a }
  end

  def test_it_does_not_stop_execution_when_hooks_returns_nil
    c = C9.new
    assert_output("a\n") { c.a }
  end

  def test_it_stops_execution_when_terminator_is_return_false_and_hook_returns_false
    c = C10.new
    assert_output('') { c.a }
  end

  def test_it_does_not_stop_execution_when_terminator_is_return_false_and_hook_returns_nil
    c = C11.new
    assert_output("a\n") { c.a }
  end

  def test_it_stops_execution_with_next_before_original
    c = C12.new
    assert_output('') { c.a }
  end

  def test_it_defines_hook_for_private_method
    c = C13.new
    assert_output("before b\nb\n") { c.__send__(:b) }
  end

  def test_it_raises_private_error_when_defining_hook_for_private_method_after_public_only_called
    definition = <<~DEFINITION
      class CPublic < C
        public_only!
        define_hook :before, :b do
          puts 'before b'
        end
      end
    DEFINITION
    assert_raises(TinyHooks::PrivateError, 'Public only mode is on and hooks for private methods (b for this time) are not available.') { eval(definition) }
  end

  def test_it_defines_hook_for_private_method_after_include_private_called_even_when_public_only_is_called
    c = C14.new
    assert_output("before b\nb\n") { c.__send__(:b) }
  end

  class D
    include TinyHooks

    def a
      puts 'a'
    end

    def b
      puts 'b'
    end

    def _b
      puts '_b'
    end

    private

    def c
      puts 'c'
    end

    def _c
      puts '_c'
    end
  end

  class D1 < D
    target! include_pattern: /(a|c)/
  end

  class D2 < D1
    define_hook :before, :a do
      puts 'before a'
    end

    define_hook :before, :c do
      puts 'before c'
    end

    define_hook :before, :_c do
      puts 'before _c'
    end
  end

  def test_when_it_includes_pattern_it_works_on_targets_matching_pattern
    d = D2.new
    assert_output("before a\na\n") { d.a }
    assert_output("before c\nc\n") { d.__send__(:c) }
    assert_output("before _c\n_c\n") { d.__send__(:_c) }
  end

  def test_when_it_includes_pattern_it_does_not_work_on_targets_against_pattern
    definition = <<~DEFINITION
      class DForB < D1
        define_hook :before, :b do
          puts 'before b'
        end
      end
    DEFINITION
    assert_raises(TinyHooks::TargetError) { eval(definition) }
  end

  class D3 < D
    target! exclude_pattern: /^_/
  end

  class D4 < D3
    define_hook :before, :a do
      puts 'before a'
    end

    define_hook :before, :b do
      puts 'before b'
    end

    define_hook :before, :c do
      puts 'before c'
    end
  end

  def test_when_it_excludes_pattern_it_works_on_targets_against_pattern
    d = D4.new
    assert_output("before a\na\n") { d.a }
    assert_output("before b\nb\n") { d.b }
    assert_output("before c\nc\n") { d.__send__(:c) }
  end

  def test_when_it_excludes_pattern_it_does_not_work_on_targets_matching_pattern
    definition = <<~DEFINITION
      class DForUnderscore < D3
        define_hook :before, :_b do
          puts 'before _b'
        end
      end
    DEFINITION
    assert_raises(TinyHooks::TargetError) { eval(definition) }
  end

  class D5 < D
    target! include_pattern: /b/, exclude_pattern: /^_/
  end

  class D6 < D5
    define_hook :before, :b do
      puts 'before b'
    end
  end

  def test_when_it_includes_and_excludes_pattern_at_the_same_time_it_applies_include_first_and_then_exclude
    d = D6.new
    assert_output("before b\nb\n") { d.b }

    definition = <<~DEFINITION
      class DForUnderscoreB < D5
        define_hook :before, :_b do
          puts 'before _b'
        end
      end
    DEFINITION
    assert_raises(TinyHooks::TargetError) { eval(definition) }
  end

  class E
    include TinyHooks

    private

    def a
      puts 'a'
    end
  end

  class E1 < E
    define_hook :before, :a do
      puts 'before a'
    end
  end

  def test_it_does_not_change_method_visibility
    e = E1.new
    assert_raises(NameError) { e.a }
  end

  def test_it_raises_error_when_target_pattern_includes_method_but_it_is_private_and_public_only_is_called
    definition = <<~DEFINITION
      class EPublic < E
        public_only!

        target! include_pattern: /a/

        define_hook :before, :a do
          puts 'before a'
        end
      end
    DEFINITION
    assert_raises(TinyHooks::TargetError) { eval(definition) }
  end
end
