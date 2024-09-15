# -*- encoding: utf-8 -*-
# stub: deep_merge 1.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "deep_merge".freeze
  s.version = "1.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steve Midgley".freeze]
  s.date = "2022-01-07"
  s.description = "Recursively merge hashes.".freeze
  s.email = "dan@kallistec.com".freeze
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://github.com/danielsdeleo/deep_merge".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Merge Deeply Nested Hashes".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 10.1"])
  s.add_development_dependency(%q<test-unit-minitest>.freeze, [">= 0"])
end
