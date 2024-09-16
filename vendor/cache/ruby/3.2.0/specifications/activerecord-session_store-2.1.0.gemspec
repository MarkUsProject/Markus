# -*- encoding: utf-8 -*-
# stub: activerecord-session_store 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "activerecord-session_store".freeze
  s.version = "2.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "2023-08-31"
  s.email = "david@loudthinking.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "https://github.com/rails/activerecord-session_store".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "An Action Dispatch session store backed by an Active Record class.".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 6.1"])
  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 6.1"])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 6.1"])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 2.0.8", "< 4"])
  s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.11", ">= 1.11.2"])
  s.add_runtime_dependency(%q<cgi>.freeze, [">= 0.3.6"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
end
