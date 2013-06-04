require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'

class SubmissionTest < ActiveSupport::TestCase

  should have_many :submission_files

  should 'automatically create a result' do
    s = Submission.make
    s.save
    assert_not_nil s.get_latest_result, 'Result was supposed to be created automatically'
    assert_equal s.get_latest_result.marking_state, Result::MARKING_STATES[:unmarked], 'Result marking_state should have been automatically set to unmarked'
  end

  should 'create a new remark result' do
    s = Submission.make
    s.save
    s.create_remark_result
    assert_not_nil s.get_remark_result, 'Remark result was supposed to be created'
    assert_equal s.get_remark_result.marking_state, Result::MARKING_STATES[:unmarked], 'Remark result marking_state should have been automatically set to unmarked'
  end

  context 'A submission with a remark result submitted' do
    setup do
      @submission = Submission.make
      @submission.save
      @submission.create_remark_result
      @result = @submission.get_remark_result
      @result.marking_state = Result::MARKING_STATES[:partial]
      @result.save
    end

    should 'return true on has_remark? call' do
      assert @submission.has_remark?
    end

    should 'return true on remark_submitted? call' do
      assert @submission.remark_submitted?
    end
  end

  context 'A submission with a remark result not submitted' do
    setup do
      @submission = Submission.make
      @submission.save
      @submission.create_remark_result
    end

    should 'return true on has_remark? call' do
      assert @submission.has_remark?
    end

    should 'return false on remark_submitted? call' do
      assert !@submission.remark_submitted?
    end
  end

  context 'A submission with no remark results' do
    setup do
      @submission = Submission.make
      @submission.save
    end
    should 'return false on has_remark? call' do
      assert !@submission.has_remark?
    end
    should 'return false on remark_submitted? call' do
      assert !@submission.remark_submitted?
    end
  end

  context 'The Submission class' do
    should 'be able to find a submission object by group name and assignment short identifier' do
      # existing submission
      assignment = Assignment.make
      group = Group.make
      grouping = Grouping.make(:assignment => assignment,
                               :group => group)
      submission = Submission.make(:grouping => grouping)

      sub2 = Submission.get_submission_by_group_and_assignment(group.group_name,
                                                                assignment.short_identifier)
      assert_not_nil(sub2)
      assert_instance_of(Submission, sub2)
      assert_equal(submission, sub2)
      # non existing test results
      assert_nil(
          Submission.get_submission_by_group_and_assignment(
                'group_name_not_there',
                'A_not_there'))
    end
  end

  should 'create a remark result' do
    s = Submission.make
    s.create_remark_result
    assert_not_nil s.get_remark_result, 'Remark result was supposed to be created'
    assert_equal s.get_remark_result.marking_state, Result::MARKING_STATES[:unmarked], 'Remark result marking_state should have been automatically set to unmarked'
  end

end
