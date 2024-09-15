# -*- encoding: utf-8 -*-
# stub: ast 2.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "ast".freeze
  s.version = "2.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["whitequark".freeze]
  s.date = "2021-01-23"
  s.description = "A library for working with Abstract Syntax Trees.".freeze
  s.email = ["whitequark@whitequark.org".freeze]
  s.homepage = "https://whitequark.github.io/ast/".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.6".freeze
  s.summary = "A library for working with Abstract Syntax Trees.".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 12.3"])
  s.add_development_dependency(%q<bacon>.freeze, ["~> 1.2"])
  s.add_development_dependency(%q<bacon-colored_output>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<coveralls>.freeze, ["~> 0.8.23"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
  s.add_development_dependency(%q<kramdown>.freeze, [">= 0"])
end
