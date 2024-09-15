# -*- encoding: utf-8 -*-
# stub: action_policy 0.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "action_policy".freeze
  s.version = "0.7.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "http://github.com/palkan/action_policy/issues", "changelog_uri" => "https://github.com/palkan/action_policy/blob/master/CHANGELOG.md", "documentation_uri" => "https://actionpolicy.evilmartians.io/", "homepage_uri" => "https://actionpolicy.evilmartians.io/", "source_code_uri" => "http://github.com/palkan/action_policy" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Vladimir Dementyev".freeze]
  s.date = "2024-07-25"
  s.description = "Authorization framework for Ruby/Rails application".freeze
  s.email = ["dementiev.vm@gmail.com".freeze]
  s.homepage = "https://github.com/palkan/action_policy".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Authorization framework for Ruby/Rails application".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<ruby-next-core>.freeze, [">= 1.0".freeze])
  s.add_development_dependency(%q<ammeter>.freeze, ["~> 1.1.3".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.15".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 13.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.9".freeze])
  s.add_development_dependency(%q<benchmark-ips>.freeze, ["~> 2.7.0".freeze])
  s.add_development_dependency(%q<i18n>.freeze, [">= 0".freeze])
end
