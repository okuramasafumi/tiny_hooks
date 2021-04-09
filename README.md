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

`extend TinyHooks` in your class/module and you're all set to use `define_hook`!

```ruby
class MyClass
  extend TinyHooks

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tiny_hooks. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/tiny_hooks/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TinyHooks project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tiny_hooks/blob/master/CODE_OF_CONDUCT.md).
