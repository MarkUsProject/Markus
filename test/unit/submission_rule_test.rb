require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class SubmissionRuleTest < ActiveSupport::TestCase
  fixtures :assignments, :submission_rules

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
end
