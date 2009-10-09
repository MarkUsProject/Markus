class GracePeriodSubmissionRule < SubmissionRule
     
  def calculate_collection_time
    return assignment.due_date + hours_sum.hours
  end
  
  # When Students commit code after the collection time, MarkUs should warn
  # the Students with a message saying that the due date has passed, and the
  # work they're submitting will probably not be graded
  def commit_after_collection_message(grouping)
    I18n.t 'submission_rules.grace_period_submission_rule.commit_after_collection_message'
  end
  
  def after_collection_message(grouping)
    I18n.t 'submission_rules.grace_period_submission_rule.after_collection_message'
  end
  
  # This message will be dislayed to Students on viewing their file manager
  # after the due date has passed, but before the calculated collection date.
  def overtime_message(grouping)
  
    # We need to know how many grace credits this grouping has left...
    grace_credits_remaining = grouping.available_grace_credits
    # How far are we into overtime?
    overtime_hours = calculate_overtime_hours_from(Time.now)
    grace_credits_to_use = calculate_deduction_amount(overtime_hours)
    if grace_credits_remaining < grace_credits_to_use
      # This grouping is out of grace credits.
      return I18n.t 'submission_rules.grace_period_submission_rule.overtime_message_without_days_left'
    else
      # This grouping still has some grace credits to spend.
      return I18n.t 'submission_rules.grace_period_submission_rule.overtime_message_with_days_left', :grace_credits_remaining => grace_credits_remaining, :grace_credits_to_use => grace_credits_to_use
    end
  end
  
  # GracePeriodSubmissionRule works with all Assignments
  def assignment_valid?
    return !assignment.nil?
  end

  def apply_submission_rule(submission)

    # If we aren't overtime, we don't need to apply a rule
    return submission if submission.revision_timestamp <= assignment.due_date
    
    # So we're overtime.  How far are we overtime?
    collection_time = submission.revision_timestamp
    due_date = assignment.due_date
    
    
    overtime_hours = calculate_overtime_hours_from(collection_time)    
    # Now we need to figure out how many Grace Credits to deduct
    deduction_amount = calculate_deduction_amount(overtime_hours)
    
   
    # And how many grace credits are available to this grouping
    available_grace_credits = submission.grouping.available_grace_credits
    
    # If the available_grace_creidts <= 0, simply get the submission
    # from the due date.
    # If the deduction_amount is greater than the amount of grace
    # credits available to this grouping, then we need to destroy
    # this submission, find the date of the last valid commit, and
    # use that as a submission, and return it.

    if available_grace_credits <= 0 
      grouping = submission.grouping
      submission.destroy
      submission = Submission.create_by_timestamp(grouping, due_date.localtime)
      return submission
    elsif available_grace_credits < deduction_amount
      grouping = submission.grouping
      submission.destroy
      collection_time = calculate_collection_date_from_credits(available_grace_credits)
      submission = Submission.create_by_timestamp(grouping, collection_time.localtime)
      # And now, a little recursion...      
      return assignment.submission_rule.apply_submission_rule(submission)
    end
   
    # Deduct Grace Credits from every member of the Grouping
    student_memberships = submission.grouping.accepted_student_memberships

    student_memberships.each do |student_membership|
      deduction = GracePeriodDeduction.new   
      deduction.membership = student_membership
      deduction.deduction = deduction_amount
      deduction.save
    end
    
    return submission
  end
  
  def description_of_rule
    I18n.t 'submission_rules.grace_period_submission_rule.description'
  end

  private 
  
  def hours_sum
    return periods.sum('hours')
  end
  
  # Given a certain number of hours into the grace periods, calculate how many credits to
  # deduct 
  def calculate_deduction_amount(overtime_hours)
    total_deduction = 0
    periods.each do |period|
      total_deduction = total_deduction + 1
      overtime_hours = overtime_hours - period.hours
      break if overtime_hours <= 0
    end
    return total_deduction
  end
  
  # Given the number of credits remaining, calculate the collection_date
  # for a Submission
  def calculate_collection_date_from_credits(grace_credits)
    hours_after_due_date = 0
    periods.each do |period|
      hours_after_due_date = hours_after_due_date + period.hours
      grace_credits = grace_credits - 1
      break if grace_credits == 0
    end
    return assignment.due_date + hours_after_due_date.hours
  end
 
end
