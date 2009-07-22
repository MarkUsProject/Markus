require 'test_helper'

class NullSubmissionRuleTest < ActiveSupport::TestCase

  def test_can_create
    rule = NullSubmissionRule.new
    rule.assignment = assignments(:assignment_1)
    rule.allow_submit_until = 1
    assert rule.save
  end
  
  def test_calculate_collection_time
    assignment = assignments(:assignment_1)
    allow_submit_until = 15
    rule = NullSubmissionRule.new
    rule.assignment = assignment
    rule.allow_submit_until = allow_submit_until
    assert_equal assignment.due_date + allow_submit_until.hours, rule.calculate_collection_time
  end
  
  def test_commit_after_collection_message
    rule = NullSubmissionRule.new
    assert_not_nil rule.commit_after_collection_message(groupings(:grouping_1))
  end
  
  def test_overtime_message
    rule = NullSubmissionRule.new
    assert_not_nil rule.overtime_message(groupings(:grouping_1))
  end
  
  def test_assignment_valid?
    rule = NullSubmissionRule.new
    assert !rule.assignment_valid?
    rule.assignment = assignments(:assignment_1)
    assert rule.assignment_valid?
  end
  
  # Shouldn't apply any penalties if Submission collection date was after due date
  def test_apply_submission_rule
    assignment = assignments(:assignment_1)
    assignment.due_date = Time.now - 2.days
    submission = submissions(:submission_1)
    submission.revision_timestamp = Time.now
    rule = NullSubmissionRule.new
    assignment.submission_rule = rule
    result_extra_marks_num = submission.result.extra_marks.size
    submission = assignment.submission_rule.apply_submission_rule(submission)
    assert_equal result_extra_marks_num, submission.result.extra_marks.size
  end
  
  def test_description_of_rule
    rule = NullSubmissionRule.new
    assert_not_nil rule.description_of_rule
  end
  
end
