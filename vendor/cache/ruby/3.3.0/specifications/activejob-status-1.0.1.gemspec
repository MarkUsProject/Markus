# -*- encoding: utf-8 -*-
# stub: activejob-status 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "activejob-status".freeze
  s.version = "1.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Savater Sebastien".freeze]
  s.date = "2024-01-12"
  s.email = "github.60k5k@simplelogin.co".freeze
  s.homepage = "https://github.com/inkstak/activejob-status".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Monitor your jobs".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activejob>.freeze, [">= 6.0".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 6.0".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 1.0".freeze])
  s.add_development_dependency(%q<timecop>.freeze, [">= 0".freeze])
end
