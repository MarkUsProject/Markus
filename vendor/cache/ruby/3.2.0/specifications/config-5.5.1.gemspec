# -*- encoding: utf-8 -*-
# stub: config 5.5.1 ruby lib

Gem::Specification.new do |s|
  s.name = "config".freeze
  s.version = "5.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rubyconfig/config/issues", "changelog_uri" => "https://github.com/rubyconfig/config/blob/master/CHANGELOG.md", "funding_uri" => "https://opencollective.com/rubyconfig/donate", "source_code_uri" => "https://github.com/rubyconfig/config" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Piotr Kuczynski".freeze, "Fred Wu".freeze, "Jacques Crocker".freeze]
  s.date = "2024-05-30"
  s.description = "Easiest way to manage multi-environment settings in any ruby project or framework: Rails, Sinatra, Padrino and others".freeze
  s.email = ["piotr.kuczynski@gmail.com".freeze, "ifredwu@gmail.com".freeze, "railsjedi@gmail.com".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "CHANGELOG.md".freeze, "CONTRIBUTING.md".freeze, "LICENSE.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "CONTRIBUTING.md".freeze, "LICENSE.md".freeze, "README.md".freeze]
  s.homepage = "https://github.com/rubyconfig/config".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Effortless multi-environment settings in Rails, Sinatra, Padrino and others".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<deep_merge>.freeze, ["~> 1.2", ">= 1.2.1"])
  s.add_development_dependency(%q<dry-validation>.freeze, ["~> 1.0", ">= 1.0.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0", ">= 12.0.0"])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.5", ">= 2.5.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.9", ">= 3.9.0"])
  s.add_development_dependency(%q<bootsnap>.freeze, [">= 1.16.0"])
  s.add_development_dependency(%q<rails>.freeze, ["= 7.1.0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 6.0.3"])
  s.add_development_dependency(%q<sprockets-rails>.freeze, ["~> 3.4.2"])
  s.add_development_dependency(%q<psych>.freeze, [">= 4"])
  s.add_development_dependency(%q<mdl>.freeze, ["~> 0.9", ">= 0.9.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.85.0"])
end
