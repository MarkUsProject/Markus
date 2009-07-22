class GracePeriodSubmissionRule < SubmissionRule
  
  #validates_numericality_of :grace_day_limit, :only_integer => true, 
  #  :greater_than_or_equal_to => 0
     
  def calculate_collection_time
    return assignment.due_date + self.hours_sum
  end
  
  def hours_sum
    return periods.sum('hours').hours
  end
  
  # When Students commit code after the collection time, MarkUs should warn
  # the Students with a message saying that the due date has passed, and the
  # work they're submitting will probably not be graded
  def commit_after_collection_message(grouping)
    I18n.t 'submission_rules.grace_day_submission_rule.commit_after_collection_message'
  end
  
  # This message will be dislayed to Students on viewing their file manager
  # after the due date has passed, but before the calculated collection date.
  def overtime_message(grouping)
    # We need to know how many grace days this grouping has left...
#    grace_days_remaining = ?
    grace_days_to_use = (self.calculate_collection_time.to_date - Time.now.to_date).to_i
    if grace_days_to_use > self.grace_day_limit
      grace_days_to_use = self.grace_day_limit
    end
    # TODO:  This is where you stopped working.    
    if grace_days_remaining < grace_days_to_use
      # This grouping doesn't have any more grace days to spend
      return I18n.t 'submission_rules.grace_day_submission_rule.overtime_message_without_days_left'
    else
      # This grouping has some grace days to spend.
      return I18n.t 'submission_rules.grace_day_submission_rule.overtime_message_with_days_left'
    end
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
