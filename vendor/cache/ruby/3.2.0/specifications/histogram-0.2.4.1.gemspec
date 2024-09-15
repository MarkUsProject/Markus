# -*- encoding: utf-8 -*-
# stub: histogram 0.2.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "histogram".freeze
  s.version = "0.2.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["John T. Prince".freeze]
  s.date = "2015-10-03"
  s.description = "gives objects the ability to 'histogram' in several useful ways".freeze
  s.email = ["jtprince@gmail.com".freeze]
  s.executables = ["histogram".freeze]
  s.files = ["bin/histogram".freeze]
  s.homepage = "https://github.com/jtprince/histogram".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.6".freeze
  s.summary = "histograms data in different ways".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.1.0"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.7.1"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 2.13.0"])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
  s.add_development_dependency(%q<narray>.freeze, [">= 0"])
end
