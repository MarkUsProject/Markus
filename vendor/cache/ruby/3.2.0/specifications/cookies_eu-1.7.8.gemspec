# -*- encoding: utf-8 -*-
# stub: cookies_eu 1.7.8 ruby lib

Gem::Specification.new do |s|
  s.name = "cookies_eu".freeze
  s.version = "1.7.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Stjepan Hadjic".freeze, "Gabrijel Skoro".freeze]
  s.date = "2021-07-31"
  s.description = "Displays a cookie consent".freeze
  s.email = ["stjepan.hadjic@infinum.hr".freeze, "gabrijel.skoro@gmail.com".freeze]
  s.homepage = "https://github.com/infinum/cookies_eu".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Displays a cookie consent. If you dont disable cokkies in settings, we assume you are ok with us using cookies".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<js_cookie_rails>.freeze, ["~> 2.2.0"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
