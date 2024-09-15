$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'shoulda/callback/matchers/version'

Gem::Specification.new do |s|
  s.name        = "shoulda-callback-matchers"
  s.version     = Shoulda::Callback::Matchers::VERSION.dup
  s.authors     = ["Beat Richartz", "Jonathan Liss"]
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.licenses    = ["MIT"]
  s.email       = "jonacom@lissismore.com"
  s.homepage    = "http://github.com/jdliss/shoulda-callback-matchers"
  s.summary     = "Making callback tests easy on the fingers and eyes"
  s.description = "Making callback tests easy on the fingers and eyes"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extensions    = 'ext/mkrf_conf.rb'

  s.add_dependency('activesupport',           '>= 3')

  s.add_development_dependency('appraisal',   '~> 0.5')
  s.add_development_dependency('aruba')
  s.add_development_dependency('bundler',     '>= 1.1')
  s.add_development_dependency('rails',       '>= 3')
  s.add_development_dependency('rake',        '~> 10')
  s.add_development_dependency('rspec-rails', '~> 3')

  if RUBY_ENGINE == 'rbx'
    s.add_development_dependency "rubysl", "~> 2"
    s.add_development_dependency "rubysl-test-unit", '~> 2'
    s.add_development_dependency "racc",   "~> 1.4"
  end
end
