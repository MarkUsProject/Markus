# -*- encoding: utf-8 -*-
# stub: activestorage 7.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "activestorage".freeze
  s.version = "7.2.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/blob/v7.2.1/activestorage/CHANGELOG.md", "documentation_uri" => "https://api.rubyonrails.org/v7.2.1/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rails/rails/tree/v7.2.1/activestorage" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "2024-08-22"
  s.description = "Attach cloud and local files in Rails applications.".freeze
  s.email = "david@loudthinking.com".freeze
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.5.11".freeze
  s.summary = "Local and cloud file storage framework.".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<actionpack>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<activejob>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<activerecord>.freeze, ["= 7.2.1".freeze])
  s.add_runtime_dependency(%q<marcel>.freeze, ["~> 1.0".freeze])
end
