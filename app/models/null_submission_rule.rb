# The NullSubmissionRule applies no penalties whatsoever.  The collection
# time is on the due date of the assignment + allow_submit_until

class NullSubmissionRule < SubmissionRule

  def calculate_collection_time
    return assignment.due_date
  end
  
  # When Students commit code after the collection time, MarkUs should warn
  # the Students with a message saying that the due date has passed, and the
  # work they're submitting will probably not be graded
  def commit_after_collection_message
    I18n.t 'submission_rules.null_submission_rule.commit_after_collection_message'
  end
  
  def overtime_message
    I18n.t 'submission_rules.null_submission_rule.overtime_message'
  end
  
  # NullSubmissionRule works with all Assignments
  def assignment_valid?
    return !assignment.nil?
  end

  # The NullSubmissionRule will not add any penalties
  def apply_submission_rule(submission)
    return submission
  end

  def description_of_rule
    I18n.t 'submission_rules.null_submission_rule.description'
  end

end
