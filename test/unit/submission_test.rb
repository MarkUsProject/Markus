require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'
class SubmissionTest < ActiveSupport::TestCase
  fixtures :all
  should_have_many :submission_files

  should "automatically create a result" do
    s = submissions(:submission_1)
    s.save
    assert_not_nil s.result, "Result was supposed to be created automatically"
    assert_equal s.result.marking_state, Result::MARKING_STATES[:unmarked], "Result marking_state should have been automatically set to unmarked"
  end

  context "The Submission class" do
    should "be able to find a submission object by group name and assignment short identifier" do
      # existing submission
      submission = submissions(:test_result_submission1)
      assignment = assignments(:assignment_test_result1)
      group = groups(:group_test_result1)
      sub2 = Submission.get_submission_by_group_and_assignment(group.group_name,
                                                                assignment.short_identifier)
      assert_not_nil(sub2)
      assert_instance_of(Submission, sub2)
      assert_equal(submission, sub2)
      # non existing test results
      assert_nil(Submission.get_submission_by_group_and_assignment("group_name_not_there", "A_not_there"))
    end
  end

end
