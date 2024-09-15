# -*- encoding: utf-8 -*-
# stub: binding_of_caller 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "binding_of_caller".freeze
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/banister/binding_of_caller/releases" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Mair (banisterfiend)".freeze]
  s.date = "2024-03-07"
  s.description = "Provides the Binding#of_caller method.\n\nUsing binding_of_caller we can grab bindings from higher up the call stack and evaluate code in that context.\nAllows access to bindings arbitrarily far up the call stack, not limited to just the immediate caller.\n\nRecommended for use only in debugging situations. Do not use this in production apps.\n".freeze
  s.email = ["jrmair@gmail.com".freeze]
  s.homepage = "https://github.com/banister/binding_of_caller".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Retrieve the binding of a method's caller, or further up the stack.".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<debug_inspector>.freeze, [">= 1.2.0"])
end
