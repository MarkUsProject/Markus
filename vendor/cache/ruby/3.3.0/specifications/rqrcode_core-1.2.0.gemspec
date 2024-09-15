# -*- encoding: utf-8 -*-
# stub: rqrcode_core 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rqrcode_core".freeze
  s.version = "1.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Duncan Robertson".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-08-26"
  s.description = "rqrcode_core is a Ruby library for encoding QR Codes. The simple\ninterface (with no runtime dependencies) allows you to create QR Code data structures.\n".freeze
  s.email = ["duncan@whomwah.com".freeze]
  s.homepage = "https://github.com/whomwah/rqrcode_core".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.2.22".freeze
  s.summary = "A library to encode QR Codes".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0".freeze])
  s.add_development_dependency(%q<standardrb>.freeze, ["~> 1.0".freeze])
end
