# -*- encoding: utf-8 -*-
# stub: browser 6.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "browser".freeze
  s.version = "6.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/fnando/browser/blob/main/CHANGELOG.md", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nando Vieira".freeze]
  s.date = "2024-04-30"
  s.description = "Do some browser detection with Ruby.".freeze
  s.email = ["me@fnando.com".freeze]
  s.homepage = "https://github.com/fnando/browser".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Do some browser detection with Ruby.".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest-autotest>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest-utils>.freeze, [">= 0"])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
  s.add_development_dependency(%q<rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-fnando>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
end
