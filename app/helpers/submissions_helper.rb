module SubmissionsHelper
  
  # Declares the rules if a user can access a submit page, 
  # given an assignment instance.
  # Also responsible for the redirects if certain rules are violated
  # Override when necessary
  def validate_submit(assignment, sub_time)
    redirect_to :action => 'index' unless assignment
    
    # check if user is allowed to submit after past due date
    rule = assignment.submission_rule  
    allowed_days_late = rule.allow_submit_until || 0
    extended_due_date = @assignment.due_date.advance(:days => allowed_days_late)
    
    unless sub_time < extended_due_date
      flash[:error] = "Deadline has passed. You cannot submit anymore at this time."
      return false
    end
       
    return true unless assignment.group_assignment?  # individual assignment
    
    # check if user has a group
    @grouping = current_user.grouping_for(assignment.id)
    if not @grouping
      flash[:error] = "You need to form a group to submit"
      return false
    end
       
    # check if user has pending status

    if @grouping.pending?(current_user)
      flash[:error] = "You need to join a group or form your own to submit."
      return false
    end
    
    # check if group has enough members to continue
    min = assignment.group_min - @grouping.memberships.count
    if min > 0
      flash[:error] = "You need to invite at least #{min} more members to submit."
      return false
    end
    
    return true
  end
  
end
