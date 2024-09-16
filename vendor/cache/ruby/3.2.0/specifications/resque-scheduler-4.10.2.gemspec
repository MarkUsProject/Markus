# -*- encoding: utf-8 -*-
# stub: resque-scheduler 4.10.2 ruby lib

Gem::Specification.new do |s|
  s.name = "resque-scheduler".freeze
  s.version = "4.10.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ben VandenBos".freeze, "Simon Eskildsen".freeze, "Ryan Biesemeyer".freeze, "Dan Buch".freeze, "Michael Bianco".freeze, "Patrick Tulskie".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-12-15"
  s.description = "    Light weight job scheduling on top of Resque.\n    Adds methods enqueue_at/enqueue_in to schedule jobs in the future.\n    Also supports queueing jobs on a fixed, cron-like schedule.\n".freeze
  s.email = ["bvandenbos@gmail.com".freeze, "sirup@sirupsen.com".freeze, "ryan@yaauie.com".freeze, "dan@meatballhat.com".freeze, "mike@mikebian.co".freeze, "patricktulskie@gmail.com".freeze]
  s.executables = ["resque-scheduler".freeze]
  s.files = ["exe/resque-scheduler".freeze]
  s.homepage = "https://github.com/resque/resque-scheduler".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Light weight job scheduling on top of Resque".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<json>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
  s.add_development_dependency(%q<timecop>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.40.0"])
  s.add_runtime_dependency(%q<mono_logger>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<redis>.freeze, [">= 3.3"])
  s.add_runtime_dependency(%q<resque>.freeze, [">= 1.27"])
  s.add_runtime_dependency(%q<rufus-scheduler>.freeze, ["~> 3.2", "!= 3.3"])
end
