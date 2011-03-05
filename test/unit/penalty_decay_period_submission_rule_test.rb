require File.join(File.dirname(__FILE__),'/../test_helper')
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require File.join(File.dirname(__FILE__),'/../blueprints/helper')
require 'shoulda'
require 'time-warp'

class PenaltyDecayPeriodSubmissionRuleTest < ActiveSupport::TestCase

  should "be able to create PenaltyDecayPeriodSubmissionRule" do
    rule = PenaltyDecayPeriodSubmissionRule.new
    rule.assignment = Assignment.make
    assert rule.save
  end
  
  context "A section with penalty_decay_period_submission rules" do
    setup do
      @grouping = Grouping.make
      sm = StudentMembership.make(:grouping => @grouping, :membership_status => StudentMembership::STATUSES[:inviter])
      @assignment = @grouping.assignment
      @rule = PenaltyDecayPeriodSubmissionRule.new
      @assignment.replace_submission_rule(@rule)
      PenaltyDecayPeriodSubmissionRule.destroy_all
      @rule.save
      
      # Instructor sets up a course.
      @assignment.due_date = Time.now + 2.days
      
      # Add two 24 hour penalty decay periods
      # Overtime begins in two days.
      add_period_helper(@assignment.submission_rule,24,10,12)
      add_period_helper(@assignment.submission_rule,24,10,12)
      # Collection date is in 4 days.
      @assignment.save
    end
    
    # A student logs in, triggering the repo folder
    
    teardown do
      destroy_repos
    end
    
    should "be able to calculate collection time" do
      assert_equal @assignment.due_date, @rule.calculate_collection_time
    end
    
    should "be able to calculate collection time for a grouping" do
      assert_equal @assignment.due_date, @rule.calculate_grouping_collection_time(@grouping)
    end
  end

  # Should not apply penalties if Submission collection date is before the due date.
  should "not apply penalties to on time submission." do
    assignment = Assignment.make
    assignment.due_date = Time.now + 1.days
    submission = Submission.make
    submission.revision_timestamp = Time.now
    rule = PenaltyDecayPeriodSubmissionRule.new
    assignment.replace_submission_rule(rule)
    result_extra_marks_num = submission.result.extra_marks.size
    submission = assignment.submission_rule.apply_submission_rule(submission)
    assert_equal result_extra_marks_num, submission.result.extra_marks.size
  end

  should "add a 10% penalty to the submission result" do
    # Student submits some files before the due date...
  end

  private

  def add_file_helper(txn, file_name, file_contents)
    path = File.join(@assignment.repository_folder, file_name)
    txn.add(path, file_contents, '')
    return txn
  end

  def add_period_helper(submission_rule, hours, deduction_amount, interval)
    period = Period.new
    period.submission_rule = submission_rule
    period.hours = hours
    period.deduction = deduction_amount
    period.interval = interval
    period.save
  end
end
