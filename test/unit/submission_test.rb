require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'
class SubmissionTest < ActiveSupport::TestCase
  
  should "automatically create a result" do
    s = submissions(:submission_1)
    s.save
    assert_not_nil s.result, "Result was supposed to be created automatically"
    assert_equal s.result.marking_state, Result::MARKING_STATES[:unmarked], "Result marking_state should have been automatically set to unmarked"
  end

end
