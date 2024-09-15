# frozen_string_literal: true

# this file is synced from dry-rb/template-gem project

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dry/core/version"

Gem::Specification.new do |spec|
  spec.name          = "dry-core"
  spec.authors       = ["Nikita Shilnikov"]
  spec.email         = ["fg@flashgordon.ru"]
  spec.license       = "MIT"
  spec.version       = Dry::Core::VERSION.dup

  spec.summary       = "A toolset of small support modules used throughout the dry-rb ecosystem"
  spec.description   = spec.summary
  spec.homepage      = "https://dry-rb.org/gems/dry-core"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "dry-core.gemspec", "lib/**/*"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["changelog_uri"]     = "https://github.com/dry-rb/dry-core/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]   = "https://github.com/dry-rb/dry-core"
  spec.metadata["bug_tracker_uri"]   = "https://github.com/dry-rb/dry-core/issues"

  spec.required_ruby_version = ">= 3.0.0"

  # to update dependencies edit project.yml
  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"
  spec.add_runtime_dependency "zeitwerk", "~> 2.6"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
