# -*- encoding: utf-8 -*-
# stub: rails_performance 1.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "rails_performance".freeze
  s.version = "1.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Igor Kasyanchuk".freeze]
  s.date = "2024-05-06"
  s.description = "3rd party dependency-free solution how to monitor performance of your Rails applications.".freeze
  s.email = ["igorkasyanchuk@gmail.com".freeze]
  s.homepage = "https://github.com/igorkasyanchuk/rails_performance".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Simple Rails Performance tracker. Alternative to the NewRelic, Datadog or other services.".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<redis>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<redis-namespace>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<browser>.freeze, [">= 0"])
  s.add_development_dependency(%q<activestorage>.freeze, [">= 0"])
  s.add_development_dependency(%q<actionmailer>.freeze, [">= 0"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<grape>.freeze, [">= 0"])
  s.add_development_dependency(%q<otr-activerecord>.freeze, [">= 0"])
  s.add_development_dependency(%q<sidekiq>.freeze, [">= 0"])
  s.add_development_dependency(%q<mimemagic>.freeze, [">= 0"])
  s.add_development_dependency(%q<delayed_job_active_record>.freeze, [">= 0"])
  s.add_development_dependency(%q<daemons>.freeze, [">= 0"])
  s.add_development_dependency(%q<wrapped_print>.freeze, [">= 0"])
  s.add_development_dependency(%q<puma>.freeze, [">= 0"])
  s.add_development_dependency(%q<sprockets-rails>.freeze, [">= 0"])
end
