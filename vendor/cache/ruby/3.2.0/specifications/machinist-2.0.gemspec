# -*- encoding: utf-8 -*-
# stub: machinist 2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "machinist".freeze
  s.version = "2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pete Yandell".freeze]
  s.date = "2012-01-13"
  s.email = ["pete@notahat.com".freeze]
  s.homepage = "http://github.com/notahat/machinist".freeze
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Fixtures aren't fun. Machinist is.".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_development_dependency(%q<activerecord>.freeze, [">= 0"])
  s.add_development_dependency(%q<mysql>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rcov>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
end
