# frozen_string_literal: true

require_relative "lib/tiny_hooks/version"

Gem::Specification.new do |spec|
  spec.name          = "tiny_hooks"
  spec.version       = TinyHooks::VERSION
  spec.authors       = ["OKURA Masafumi"]
  spec.email         = ["masafumi.o1988@gmail.com"]

  spec.summary       = "Simple, tiny and general hooks control."
  spec.description   = "Simple, tiny and general hooks control."
  spec.homepage      = "https://github.com/okuramasafumi/tiny_hooks"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
