# -*- encoding: utf-8 -*-
# stub: dry-inflector 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-inflector".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-inflector/issues", "changelog_uri" => "https://github.com/dry-rb/dry-inflector/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-inflector" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Luca Guidi".freeze, "Andrii Savchenko".freeze, "Abinoam P. Marques Jr.".freeze]
  s.date = "2022-11-04"
  s.description = "String inflections for dry-rb".freeze
  s.email = ["me@lucaguidi.com".freeze, "andrey@aejis.eu".freeze, "abinoam@gmail.com".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-inflector".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "String inflections for dry-rb".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
end
