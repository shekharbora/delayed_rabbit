require_relative "lib/delayed_rabbit/version"

Gem::Specification.new do |spec|
  spec.name          = "delayed_rabbit"
  spec.version       = DelayedRabbit::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "A lightweight Ruby gem for scheduling delayed background jobs using RabbitMQ"
  spec.description   = "delayed_rabbit provides a simple interface for scheduling background jobs with delays using RabbitMQ's delayed message exchange plugin"
  spec.homepage      = "https://github.com/yourusername/delayed_rabbit"
  spec.license       = "MIT"
  spec.required_ruby_version = "~> 3.2"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "bunny", "~> 2.18"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
