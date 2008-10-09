module SubmissionsHelper
  
  # Declares the rules if a user can access a submit page, 
  # given an assignment instance.
  # Also responsible for the redirects if certain rules are violated
  # Override when necessary
  def can_submit?(assignment)
    redirect_to :action => 'index' unless assignment
    return true unless assignment.group_assignment?  # individual assignment
    
  end
  
  
  def validate_submit(assignment)
    # TODO do validation
    # you must be in a group to submit
  end
  
  # Returns true if submission is accepted
  def allow_late_submissions?(submission)
    due_date = submission.assignment.due_date
    last_submission = submission.last_submission
    
    
  end
  
  
end
