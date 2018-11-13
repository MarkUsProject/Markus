# The NoLateSubmissionRule applies no penalties whatsoever.  The collection
# time is on the due date of the assignment + allow_submit_until

class NoLateSubmissionRule < SubmissionRule

  def overtime_message(grouping)
    NoLateSubmissionRule.human_attribute_name(:after_collection_message)
  end

  # NoLateSubmissionRule works with all Assignments
  def assignment_valid?
    !assignment.nil?
  end

  # The NoLateSubmissionRule will not add any penalties
  def apply_submission_rule(submission)
    submission
  end

  def grader_tab_partial
    'submission_rules/no_late/grader_tab'
  end
end
