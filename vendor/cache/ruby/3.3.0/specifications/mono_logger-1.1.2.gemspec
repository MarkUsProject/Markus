# -*- encoding: utf-8 -*-
# stub: mono_logger 1.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "mono_logger".freeze
  s.version = "1.1.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steve Klabnik".freeze]
  s.date = "2023-04-06"
  s.description = "A lock-free logger compatible with Ruby 2.0. Ruby does not allow you to request a lock in a trap handler because that could deadlock, so Logger is not sufficient.".freeze
  s.email = ["steve@steveklabnik.com".freeze]
  s.homepage = "http://github.com/steveklabnik/mono_logger".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.2.15".freeze
  s.summary = "A lock-free logger compatible with Ruby 2.0.".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0".freeze])
end
