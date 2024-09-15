# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cookies_eu/version'

Gem::Specification.new do |spec|
  spec.name          = "cookies_eu"
  spec.version       = CookiesEu::VERSION
  spec.authors       = ["Stjepan Hadjic", "Gabrijel Skoro"]
  spec.email         = ["stjepan.hadjic@infinum.hr", "gabrijel.skoro@gmail.com"]
  spec.description   = %q{Displays a cookie consent}
  spec.summary       = %q{Displays a cookie consent. If you dont disable cokkies in settings, we assume you are ok with us using cookies}
  spec.homepage      = "https://github.com/infinum/cookies_eu"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "js_cookie_rails", "~> 2.2.0"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
