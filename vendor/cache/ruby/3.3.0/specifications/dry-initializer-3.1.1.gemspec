# -*- encoding: utf-8 -*-
# stub: dry-initializer 3.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-initializer".freeze
  s.version = "3.1.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-initializer/issues", "changelog_uri" => "https://github.com/dry-rb/dry-initializer/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-initializer" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Vladimir Kochnev (marshall-lee)".freeze, "Andrew Kozin (nepalez)".freeze]
  s.date = "2022-01-19"
  s.description = "DSL for declaring params and options of the initializer".freeze
  s.email = ["andrew.kozin@gmail.com".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-initializer".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "DSL for declaring params and options of the initializer".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
end
