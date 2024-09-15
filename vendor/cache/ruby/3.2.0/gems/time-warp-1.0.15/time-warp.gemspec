# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "time-warp"
  spec.version       = "1.0.15"
  spec.authors       = ["Barry Hess"]
  spec.email         = "barry@getHarvest.com"
  spec.summary       = "Warp time in your tests"
  spec.description   = "TimeWarp is a ruby library for manipulating times in automated tests."
  spec.homepage      = "http://github.com/harvesthq/time-warp"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
