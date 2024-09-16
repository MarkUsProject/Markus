# -*- encoding: utf-8 -*-
# stub: shoulda-callback-matchers 1.1.4 ruby lib
# stub: ext/mkrf_conf.rb

Gem::Specification.new do |s|
  s.name = "shoulda-callback-matchers".freeze
  s.version = "1.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Beat Richartz".freeze, "Jonathan Liss".freeze]
  s.date = "2016-05-14"
  s.description = "Making callback tests easy on the fingers and eyes".freeze
  s.email = "jonacom@lissismore.com".freeze
  s.extensions = ["ext/mkrf_conf.rb".freeze]
  s.files = ["ext/mkrf_conf.rb".freeze]
  s.homepage = "http://github.com/jdliss/shoulda-callback-matchers".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Making callback tests easy on the fingers and eyes".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3"])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 0.5"])
  s.add_development_dependency(%q<aruba>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.1"])
  s.add_development_dependency(%q<rails>.freeze, [">= 3"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10"])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3"])
end
