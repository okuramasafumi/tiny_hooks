# frozen_string_literal: true

require 'test_helper'

class TinyHooksTest < Minitest::Test
  class C
    extend TinyHooks

    def a
      puts 'a'
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
      class C8 < C
        restore_original :missing
      end
    DEFINITION
    assert_raises(NameError) { eval(definition) }
  end
end
