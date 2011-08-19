require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class NoLateSubmissionRuleTest < ActiveSupport::TestCase
  fixtures :all

  should "be able to create NoLateSubmissionRule" do
    rule = NoLateSubmissionRule.new
    rule.assignment = assignments(:assignment_1)
    assert rule.save
  end

  context "A section with no_late_submission rules" do
    setup do
      @grouping = Grouping.make
      sm = StudentMembership.make(
               :grouping => @grouping,
               :membership_status => StudentMembership::STATUSES[:inviter])
      @assignment = @grouping.assignment
      @rule = @assignment.submission_rule
    end

    should "be able to calculate collection time" do
      assert_equal @assignment.due_date, @rule.calculate_collection_time
    end

    should "be able to calculate collection time for a grouping" do
      assert_equal @assignment.due_date,
                   @rule.calculate_grouping_collection_time(@grouping)
    end
  end

  # Shouldn't apply any penalties if Submission collection date was after due date
  should "not change the assignment at all when applied" do
    assignment = assignments(:assignment_1)
    assignment.due_date = Time.now - 2.days
    submission = submissions(:submission_1)
    submission.revision_timestamp = Time.now
    rule = NoLateSubmissionRule.new
    assignment.replace_submission_rule(rule)
    result_extra_marks_num = submission.result.extra_marks.size
    submission = assignment.submission_rule.apply_submission_rule(submission)
    assert_equal result_extra_marks_num, submission.result.extra_marks.size
  end



end
