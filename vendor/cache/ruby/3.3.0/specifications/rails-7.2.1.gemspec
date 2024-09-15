# -*- encoding: utf-8 -*-
# stub: rails 7.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rails".freeze
  s.version = "7.2.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 1.8.11".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/releases/tag/v7.2.1", "documentation_uri" => "https://api.rubyonrails.org/v7.2.1/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rails/rails/tree/v7.2.1" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "2024-08-22"
  s.description = "Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity. It encourages beautiful code by favoring convention over configuration.".freeze
  s.email = "david@loudthinking.com".freeze
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.5.11".freeze
  s.summary = "Full-stack web application framework.".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<actionpack>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<actionview>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<activemodel>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<activerecord>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<actionmailer>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<activejob>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<actioncable>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<activestorage>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<actionmailbox>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<actiontext>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<bundler>.freeze, [">= 1.15.0".freeze])
end
