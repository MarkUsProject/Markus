require 'simplecov'
SimpleCov.start

require 'rspec'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.color = true
end

TESTFILES = File.dirname(__FILE__) + "/testfiles"


