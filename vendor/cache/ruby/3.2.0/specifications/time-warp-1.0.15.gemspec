# -*- encoding: utf-8 -*-
# stub: time-warp 1.0.15 ruby lib

Gem::Specification.new do |s|
  s.name = "time-warp".freeze
  s.version = "1.0.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Barry Hess".freeze]
  s.date = "2014-07-25"
  s.description = "TimeWarp is a ruby library for manipulating times in automated tests.".freeze
  s.email = "barry@getHarvest.com".freeze
  s.homepage = "http://github.com/harvesthq/time-warp".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Warp time in your tests".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.6"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
