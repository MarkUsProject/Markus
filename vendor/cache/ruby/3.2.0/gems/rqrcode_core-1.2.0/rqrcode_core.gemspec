lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rqrcode_core/version"

Gem::Specification.new do |spec|
  spec.name = "rqrcode_core"
  spec.version = RQRCodeCore::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Duncan Robertson"]
  spec.email = ["duncan@whomwah.com"]

  spec.summary = "A library to encode QR Codes"
  spec.description = <<~EOF
    rqrcode_core is a Ruby library for encoding QR Codes. The simple
    interface (with no runtime dependencies) allows you to create QR Code data structures.
  EOF
  spec.homepage = "https://github.com/whomwah/rqrcode_core"
  spec.license = "MIT"

  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "standardrb", "~> 1.0"
end
