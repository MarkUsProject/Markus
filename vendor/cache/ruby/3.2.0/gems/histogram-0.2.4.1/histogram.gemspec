# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'histogram/version'

Gem::Specification.new do |spec|
  spec.name          = "histogram"
  spec.version       = Histogram::VERSION
  spec.authors       = ["John T. Prince"]
  spec.email         = ["jtprince@gmail.com"]
  spec.description   = %q{gives objects the ability to 'histogram' in several useful ways}
  spec.summary       = %q{histograms data in different ways}
  spec.homepage      = "https://github.com/jtprince/histogram"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  [ "bundler ~> 1.3",
    "rake ~> 10.1.0",
    "simplecov ~> 0.7.1",
    "rspec ~> 2.13.0",
    "rdoc"
  ].each do |argline|
    spec.add_development_dependency *argline.split(' ', 2).compact
  end

  unless RUBY_PLATFORM =~ /java/
    spec.add_development_dependency "narray"
  end
end
