# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'js_cookie_rails/version'

Gem::Specification.new do |spec|
  spec.name          = "js_cookie_rails"
  spec.version       = JsCookieRails::VERSION
  spec.authors       = ["Alessandro Lepore"]
  spec.email         = ["a.lepore@freegoweb.it"]

  spec.summary       = %q{Adds js-cookie to the Rails asset pipeline.}
  spec.description   = <<-EOL
    JavaScript Cookie is a simple, lightweight JavaScript API for handling cookies.
    This gem allows for its easy inclusion into the rails asset pipeline.
  EOL
  spec.homepage      = "https://github.com/freego/js_cookie_rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 3.1"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
