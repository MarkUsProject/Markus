require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class NoLateSubmissionRuleTest < ActiveSupport::TestCase

  should 'be able to create NoLateSubmissionRule' do
    rule = NoLateSubmissionRule.new
    rule.assignment = Assignment.make
    assert rule.save
  end

  context 'A section with no_late_submission rules' do
    setup do
      @grouping = Grouping.make
      sm = StudentMembership.make(
               grouping: @grouping,
               membership_status: StudentMembership::STATUSES[:inviter])
      @assignment = @grouping.assignment
      @rule = @assignment.submission_rule
    end

    should 'be able to calculate collection time' do
      assert_equal @assignment.due_date, @rule.calculate_collection_time
    end

    should 'be able to calculate collection time for a grouping' do
      assert_equal @assignment.due_date,
                   @rule.calculate_grouping_collection_time(@grouping)
    end
  end

  # Shouldn't apply any penalties if Submission collection date was after due date
  should 'not change the assignment at all when applied' do
    assignment = Assignment.make
    grouping = Grouping.make(assignment: assignment)
    assignment.due_date = Time.now - 2.days
    submission = Submission.make(grouping: grouping)
    submission.revision_timestamp = Time.now
    rule = NoLateSubmissionRule.new
    assignment.replace_submission_rule(rule)
    result_extra_marks_num = submission.get_latest_result.extra_marks.size
    submission = assignment.submission_rule.apply_submission_rule(submission)
    assert_equal result_extra_marks_num, submission.get_latest_result.extra_marks.size
  end



end
