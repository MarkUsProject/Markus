require_relative 'matchers/version'
require_relative 'matchers/rails_version_helper'

if defined?(RSpec)
  require_relative 'matchers/integrations/rspec'
end

require_relative 'matchers/integrations/test_unit'
