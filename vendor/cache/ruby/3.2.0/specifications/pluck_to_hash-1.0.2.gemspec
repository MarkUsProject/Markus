# -*- encoding: utf-8 -*-
# stub: pluck_to_hash 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "pluck_to_hash".freeze
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Girish S".freeze]
  s.date = "2017-08-09"
  s.description = "Extend ActiveRecord pluck to return hash instead of an array. Useful when plucking multiple columns.".freeze
  s.email = ["girish.sonawane@gmail.com".freeze]
  s.homepage = "https://github.com/girishso/pluck_to_hash".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Extend ActiveRecord pluck to return hash".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.7"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
  s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<pg>.freeze, ["~> 0.19.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<values>.freeze, ["~> 1.8"])
  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4.0.2"])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.0.2"])
end
