# -*- encoding: utf-8 -*-
# stub: dry-configurable 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-configurable".freeze
  s.version = "1.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-configurable/issues", "changelog_uri" => "https://github.com/dry-rb/dry-configurable/blob/main/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-configurable" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andy Holland".freeze]
  s.date = "2023-07-16"
  s.description = "A mixin to add configuration functionality to your classes".freeze
  s.email = ["andyholland1991@aol.com".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-configurable".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.3.26".freeze
  s.summary = "A mixin to add configuration functionality to your classes".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<dry-core>.freeze, ["~> 1.0".freeze, "< 2".freeze])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2.6".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
end
