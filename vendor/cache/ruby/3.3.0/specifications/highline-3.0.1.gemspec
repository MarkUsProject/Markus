# -*- encoding: utf-8 -*-
# stub: highline 3.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "highline".freeze
  s.version = "3.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["James Edward Gray II".freeze]
  s.date = "2024-01-20"
  s.description = "A high-level IO library that provides validation, type conversion, and more for\ncommand-line interfaces. HighLine also includes a complete menu system that can\ncrank out anything from simple list selection to complete shells with just\nminutes of work.\n".freeze
  s.email = "james@graysoftinc.com".freeze
  s.extra_rdoc_files = ["README.md".freeze, "TODO".freeze, "Changelog.md".freeze, "LICENSE".freeze]
  s.files = ["Changelog.md".freeze, "LICENSE".freeze, "README.md".freeze, "TODO".freeze]
  s.homepage = "https://github.com/JEG2/highline".freeze
  s.licenses = ["Ruby".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "HighLine is a high-level command-line IO library.".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<dry-types>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<reline>.freeze, [">= 0".freeze])
end
