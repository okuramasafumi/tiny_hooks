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

## Difference between TinyHooks and ActiveSupport::Callbacks

While `TinyHooks` and `ActiveSupport::Callbacks` share the same purpose, there are a few major differences.

* While `ActiveSupport::Callbacks` has a set of methods for callbacks to work, `TinyHooks` has only one method.
* You can apply callbacks/hooks into any existing methods without any changes with `TinyHooks`, while you need to change methods to call `run_callbacks` method within them to apply callbacks with `ActiveSupport::Callbacks`.

In short, `TinyHooks` is simpler while `ActiveSupport::Callbacks` allows more control over callbacks.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tiny_hooks. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/tiny_hooks/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TinyHooks project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tiny_hooks/blob/master/CODE_OF_CONDUCT.md).
