require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class SubmissionRuleTest < ActiveSupport::TestCase

  def teardown
    destroy_repos
  end

  should "raise a whole bunch of NotImplemented errors" do
    rule = SubmissionRule.new
    rule.assignment = Assignment.make

    assert_raise NotImplementedError do
      rule.commit_after_collection_message
    end

    assert_raise NotImplementedError do
      rule.overtime_message
    end

    assert_raise NotImplementedError do
      rule.assignment_valid?
    end

    assert_raise NotImplementedError do
      rule.apply_submission_rule(nil)
    end

    assert_raise NotImplementedError do
      rule.description_of_rule
    end
  end

  context "Grace period ids" do
    setup do

	  # Create SubmissionRule with default type 'GracePeriodSubmissionRule'
	  @submission_rule = GracePeriodSubmissionRule.make
	  sub_rule_id = @submission_rule.id

	  # Randomly create five periods for this SubmissionRule (ids unsorted):

	  # Create the first period
	  @period = Period.make(:submission_rule_id => sub_rule_id)
	  first_period_id = @period.id

	  # Create two other periods
	  @period = Period.make(:id => first_period_id + 2, :submission_rule_id => sub_rule_id)
	  @period = Period.make(:id => first_period_id + 4, :submission_rule_id => sub_rule_id)

	  # Create two other periods
	  @period = Period.make(:id => first_period_id + 1, :submission_rule_id => sub_rule_id)
	  @period = Period.make(:id => first_period_id + 3, :submission_rule_id => sub_rule_id)
    end

    should "sort in ascending order" do
    # Loop through periods for this SubmissionRule and verify the ids are
    # sorted in ascending order
	  previous_id = @submission_rule.periods[0][:id]
	  for i in (1..4) do
	     assert @submission_rule.periods[i][:id] > previous_id
	     previous_id = @submission_rule.periods[i][:id]
	  end
    end
  end

  context "Penalty period ids" do
    setup do

	  # Create SubmissionRule with default type 'PenaltyPeriodSubmissionRule'
	  @submission_rule = PenaltyPeriodSubmissionRule.make
	  sub_rule_id = @submission_rule.id

	  # Randomly create five periods for this SubmissionRule (ids unsorted):

	  # Create the first period
	  @period = Period.make(:submission_rule_id => sub_rule_id)
	  first_period_id = @period.id

	  # Create two other periods
	  @period = Period.make(:id => first_period_id + 2, :submission_rule_id => sub_rule_id)
	  @period = Period.make(:id => first_period_id + 4, :submission_rule_id => sub_rule_id)

	  # Create two other periods
	  @period = Period.make(:id => first_period_id + 1, :submission_rule_id => sub_rule_id)
	  @period = Period.make(:id => first_period_id + 3, :submission_rule_id => sub_rule_id)
    end

    should "sort in ascending order" do
	  # Loop through periods for this SubmissionRule and verify the ids are sorted in ascending order
	  previous_id = @submission_rule.periods[0][:id]
	  for i in (1..4) do
	     assert @submission_rule.periods[i][:id] > previous_id
	     previous_id = @submission_rule.periods[i][:id]
	  end
    end
  end

  context "Assignment with a due date in 2 days" do
    setup do
      @assignment = Assignment.make
    end

    should "have not be able to collect" do
      assert !@assignment.submission_rule.can_collect_now?,
             "assignment cannot be collected now"
    end

    should "be able to get due date" do
      assert_equal @assignment.due_date,
                   @assignment.submission_rule.get_collection_time
    end
  end

  context "Assignment with a past due date" do
    setup do
      @assignment = Assignment.make(:due_date => 2.days.ago)
    end

    should "should be able to collect" do
      assert_equal(@assignment.due_date, @assignment.submission_rule.get_collection_time,
        "due date should be equal to collection time for no late submission rule")
      # due date is two days ago, so it can be collected
      assert @assignment.submission_rule.can_collect_now?,
             "assignment can be collected now"
    end
  end

end
