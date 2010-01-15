# The NoLateSubmissionRule applies no penalties whatsoever.  The collection
# time is on the due date of the assignment + allow_submit_until

class NoLateSubmissionRule < SubmissionRule

  def calculate_collection_time
    return assignment.due_date
  end
  
  # When Students commit code after the collection time, MarkUs should warn
  # the Students with a message saying that the due date has passed, and the
  # work they're submitting will probably not be graded
  def commit_after_collection_message(grouping)
    I18n.t 'submission_rules.no_late_submission_rule.commit_after_late_message'
  end
  
  def after_collection_message(grouping)
    I18n.t 'submission_rules.no_late_submission_rule.no_late_message'
  end
  
  def overtime_message(grouping)
    I18n.t 'submission_rules.no_late_submission_rule.no_late_message'
  end
  
  # NoLateSubmissionRule works with all Assignments
  def assignment_valid?
    return !assignment.nil?
  end

  # The NoLateSubmissionRule will not add any penalties
  def apply_submission_rule(submission)
    return submission
  end

  def description_of_rule
    I18n.t 'submission_rules.no_late_submission_rule.description'
  end
  
  def grader_tab_partial
    return 'submission_rules/no_late/grader_tab'
  end
end
