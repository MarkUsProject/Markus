# The NoLateSubmissionRule applies no penalties whatsoever.  The collection
# time is on the due date of the assignment + allow_submit_until

class NoLateSubmissionRule < SubmissionRule

  # When Students commit code after the collection time, MarkUs should warn
  # the Students with a message saying that the due date has passed, and the
  # work they're submitting will probably not be graded
  def commit_after_collection_message
    I18n.t 'submission_rules.no_late_submission_rule.commit_after_late_message'
  end

  def after_collection_message
    I18n.t 'submission_rules.no_late_submission_rule.no_late_message'
  end

  def overtime_message(grouping)
    I18n.t 'submission_rules.no_late_submission_rule.no_late_message'
  end

  # NoLateSubmissionRule works with all Assignments
  def assignment_valid?
    !assignment.nil?
  end

  # The NoLateSubmissionRule will not add any penalties
  def apply_submission_rule(submission)
    submission
  end

  def description_of_rule
    I18n.t 'submission_rules.no_late_submission_rule.description'
  end

  def grader_tab_partial
    'submission_rules/no_late/grader_tab'
  end
end
