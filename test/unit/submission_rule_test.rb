require 'test_helper'

class SubmissionRuleTest < ActiveSupport::TestCase

  def test_can_create
    rule = SubmissionRule.new
    rule.assignment = assignments(:assignment_1)
    assert rule.save
  end

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
