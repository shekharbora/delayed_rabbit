require_relative "lib/delayed_rabbit/version"

Gem::Specification.new do |spec|
  spec.name          = "delayed_rabbit"
  spec.version       = DelayedRabbit::VERSION
  spec.authors       = ["ShekharBora"]
  spec.email         = ["chandu42011@gmail.com"]

  spec.summary       = "A lightweight Ruby gem for scheduling delayed background jobs using RabbitMQ"
  spec.description   = "delayed_rabbit provides a simple interface for scheduling background jobs with delays using RabbitMQ's delayed message exchange plugin"
  spec.homepage      = "https://github.com/shekharbora/delayed_rabbit"
  spec.license       = "MIT"
  spec.required_ruby_version = "~> 3.2"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "tasks/**/*", "README.md", "CHANGELOG.md", "LICENSE.txt"]
  end
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "bunny", "~> 2.18"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "mocha", "~> 2.0"
  spec.add_development_dependency "railties", ">= 6.0"
end
