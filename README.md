[![Ruby](https://github.com/okuramasafumi/tiny_hooks/actions/workflows/main.yml/badge.svg)](https://github.com/okuramasafumi/tiny_hooks/actions/workflows/main.yml)

# TinyHooks

A tiny gem to define hooks.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tiny_hooks'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install tiny_hooks

## Usage

`include TinyHooks` in your class/module and you're all set to use `define_hook`!

```ruby
class MyClass
  include TinyHooks

  def my_method
    puts 'my method'
  end

  define_hook :before, :my_method do
    puts 'my before hook'
  end
end

MyClass.new.my_method
# => "my before hook\nmy method\n"
```

You can also call `define_hook` with method name as a third argument.

```ruby
class MyClass
  include TinyHooks

  def my_method
    puts 'my method'
  end

  def my_before_hook
    puts 'my before hook'
  end

  define_hook :before, :my_method, :my_before_hook
end

MyClass.new.my_method
# => "my before hook\nmy method\n"
```

TinyHooks shines when the class/module is the base class/module of your library and your users will inherit/include it. In these cases, end users can define hooks to the methods you provide. The only thing you have to do is to provide the list of methods.

### Halting

You can halt hook and method body execution by `throw`ing `:abort`.

```ruby
class MyClass
  include TinyHooks

  def my_method
    puts 'my method'
  end

  define_hook :before, :my_method do
    throw :abort
    puts 'my before hook'
  end
end

MyClass.new.my_method
# => ""
```

You can change how to halt from two options: throwing `:abort` and returning `false`. This can be done via `terminator` option.

```ruby
class MyClass
  include TinyHooks

  def my_method
    puts 'my method'
  end

  define_hook :before, :my_method, terminator: :return_false do
    false
  end
end

MyClass.new.my_method
# => ""
```

### Targeting for hooks

You can limit the targets for hooks in two ways. You can enable hooks for public methods only by using `public_only!` method and include/exclude targets with Regexp pattern by using `targets!` method.

```ruby
class MyClass
  include TinyHooks

  def my_method
    puts 'my method'
  end

  private

  def my_private_method
    puts 'my private method'
  end
end

class MyClassWithPublicOnly < MyClass
  public_only!

  define_hook :before, :my_private_method do
    puts 'my_private_method'
  end
  # => This causes PrivateError
end

class MyClassWithExclude < MyClass
  target! exclude_pattern: /my_method/

  define_hook :before, :my_method do
    puts 'my_method'
  end
  # => This causes TargetError
end
```

You can call `include_private!` method to disable the effect of `public_only!`.

### Conditional hooks

You can add `if` option to `define_hook` call. `if` option must be a Proc and is evaluated in context of an instance.

```ruby
class MyClass
  include TinyHooks

  def initialize(hook_enabled = true)
    @hook_enabled = hook_enabled
  end

  def my_method
    puts 'my method'
  end

  def hook_enabled?
    @hook_enabled
  end

  define_hook :before, :my_method, if: -> { hook_enabled? } do
    puts 'my before hook'
  end
end

MyClass.new(true).my_method
# => "my before hook\nmy method\n"

MyClass.new(false).my_method
# => "my method\n"
```

## Differences between TinyHooks and ActiveSupport::Callbacks

While `TinyHooks` and `ActiveSupport::Callbacks` share the same purpose, there are a few major differences.

### Differences in usage

* While `ActiveSupport::Callbacks` has a set of methods for callbacks to work, `TinyHooks` has only one method.
* You can apply callbacks/hooks into any existing methods without any changes with `TinyHooks`, while you need to change methods to call `run_callbacks` method within them to apply callbacks with `ActiveSupport::Callbacks`.

### Differences in performance

According to the [benchmark](https://github.com/okuramasafumi/tiny_hooks/blob/main/benchmark/compare_to_as_callbacks.rb), `TinyHooks` is 1.6 times as fast as `ActiveSupport::Callbacks` when before and after callbacks are applied, and twice as fast when no callbacks are applied.

The result on my machine:

```
Warming up --------------------------------------
       ActiveSupport   246.181k i/s -    256.956k times in 1.043769s (4.06μs/i)
           TinyHooks   282.834k i/s -    293.502k times in 1.037719s (3.54μs/i)
Calculating -------------------------------------
       ActiveSupport   230.196k i/s -    738.542k times in 3.208320s (4.34μs/i)
           TinyHooks   373.057k i/s -    848.501k times in 2.274453s (2.68μs/i)

Comparison:
           TinyHooks:    373057.2 i/s
       ActiveSupport:    230195.9 i/s - 1.62x  slower

Warming up --------------------------------------
ActiveSupport no callback set     1.992M i/s -      2.096M times in 1.052258s (501.99ns/i)
    TinyHooks no callback set     3.754M i/s -      3.791M times in 1.009753s (266.39ns/i)
                        Plain     3.852M i/s -      3.955M times in 1.026654s (259.57ns/i)
Calculating -------------------------------------
ActiveSupport no callback set     2.005M i/s -      5.976M times in 2.980861s (498.79ns/i)
    TinyHooks no callback set     4.025M i/s -     11.262M times in 2.798054s (248.46ns/i)
                        Plain     3.765M i/s -     11.557M times in 3.069944s (265.63ns/i)

Comparison:
    TinyHooks no callback set:   4024854.4 i/s
                        Plain:   3764695.4 i/s - 1.07x  slower
ActiveSupport no callback set:   2004848.9 i/s - 2.01x  slower
```

### Differences in functionality

There are few things TinyHooks doesn't cover. For example, TinyHooks doesn't support `unless` option in `define_hook` method or Symbol as a callback body since they are just syntax sugar.

One of the features TinyHooks doesn't have is `reset_callbacks` which resets all callbacks with given condition. In order to do this, you must call `restore_original` method in iteration.

### Conclusion

In short, in most cases, TinyHooks is simpler, easier and faster solution.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tiny_hooks. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/tiny_hooks/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TinyHooks project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tiny_hooks/blob/master/CODE_OF_CONDUCT.md).
