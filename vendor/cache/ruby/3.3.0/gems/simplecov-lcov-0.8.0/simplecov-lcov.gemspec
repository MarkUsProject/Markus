# -*- encoding: utf-8 -*-
# stub: simplecov-lcov 0.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "simplecov-lcov".freeze
  s.version = "0.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["fortissimo1997".freeze]
  s.date = "2020-02-18"
  s.description = "Custom SimpleCov formatter to generate a lcov style coverage.".freeze
  s.email = "fortissimo1997@gmail.com".freeze
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.markdown"
  ]
  s.files = [
    ".coveralls.yml",
    ".document",
    ".rspec",
    ".tachikoma.yml",
    ".travis.yml",
    "Gemfile",
    "LICENSE.txt",
    "README.markdown",
    "Rakefile",
    "VERSION",
    "lib/simple_cov_lcov/configuration.rb",
    "lib/simplecov-lcov.rb",
    "simplecov-lcov.gemspec",
    "spec/configuration_spec.rb",
    "spec/fixtures/app/models/user.rb",
    "spec/fixtures/hoge.rb",
    "spec/fixtures/lcov/spec-fixtures-app-models-user.rb.branch.lcov",
    "spec/fixtures/lcov/spec-fixtures-app-models-user.rb.lcov",
    "spec/fixtures/lcov/spec-fixtures-hoge.rb.branch.lcov",
    "spec/fixtures/lcov/spec-fixtures-hoge.rb.lcov",
    "spec/simplecov-lcov_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/fortissimo1997/simplecov-lcov".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Custom SimpleCov formatter to generate a lcov style coverage.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.18"])
      s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
      s.add_development_dependency(%q<activesupport>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<rdoc>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.18"])
      s.add_dependency(%q<coveralls>.freeze, [">= 0"])
      s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rdoc>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.18"])
    s.add_dependency(%q<coveralls>.freeze, [">= 0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
  end
end

