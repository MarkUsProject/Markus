# :enddoc:

include Shoulda::Callback::Matchers::RailsVersionHelper

# in environments where test/unit is not required, this is necessary
unless defined?(Test::Unit::TestCase)
  begin
    require rails_version >= '4.1' ? 'minitest' : 'test/unit/testcase'
  rescue LoadError
    # silent
  end
end

if defined?(Test::Unit::TestCase) && (defined?(::ActiveModel) || defined?(::ActiveRecord))
  require 'shoulda/callback/matchers/active_model'

  Test::Unit::TestCase.tap do |test_unit|
    test_unit.send :include, Shoulda::Callback::Matchers::ActiveModel
    test_unit.send :extend, Shoulda::Callback::Matchers::ActiveModel
  end

elsif defined?(MiniTest::Unit::TestCase) && (defined?(::ActiveModel) || defined?(::ActiveRecord))
  require 'shoulda/callback/matchers/active_model'

  MiniTest::Unit::TestCase.tap do |minitest_unit|
    minitest_unit.send :include, Shoulda::Callback::Matchers::ActiveModel
    minitest_unit.send :extend, Shoulda::Callback::Matchers::ActiveModel
  end

end
