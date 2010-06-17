require File.dirname(__FILE__) + '/../test_helper'
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require 'shoulda'

class SubmissionRuleTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    setup_group_fixture_repos
  end

  def teardown
    destroy_repos
  end

  def test_can_create
    rule = SubmissionRule.new
    rule.assignment = assignments(:assignment_1)
    assert rule.save
  end

  def test_can_collect_now_false
    a = assignments(:assignment_1)
    assert !a.submission_rule.can_collect_now?
  end

  def test_can_collect_now_true
    a = assignments(:assignment_4)
    assert a.submission_rule.can_collect_now?
  end

  def test_get_collection_time
    a = assignments(:assignment_4)
    assert_equal(a.due_date, a.submission_rule.get_collection_time)
  end

  # TODO test get collection time when submission rule is different than no
  # submission rules

  def test_has_required_methods
    rule = SubmissionRule.new
    rule.assignment = assignments(:assignment_1)

    assert_raise NotImplementedError do
      rule.calculate_collection_time
    end

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
	  clear_fixtures

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
	  # Loop through periods for this SubmissionRule and verify the ids are sorted in ascending order
	  previous_id = @submission_rule.periods[0][:id]
	  for i in (1..4) do
	     assert @submission_rule.periods[i][:id] > previous_id
	     previous_id = @submission_rule.periods[i][:id]
	  end
    end
  end

  context "Penalty period ids" do
    setup do
	  clear_fixtures

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

end
