module SubmissionsHelper
  
  # Declares the rules if a user can access a submit page, 
  # given an assignment instance.
  # Also responsible for the redirects if certain rules are violated
  # Override when necessary
  def validate_submit(assignment)
    redirect_to :action => 'index' unless assignment
    return true unless assignment.group_assignment?  # individual assignment
    
    # check if user has a group
    @group = current_user.group_for(assignment.id)
    if not @group
      redirect_to :controller => "groups", 
        :action => 'creategroup', :id => assignment.id
      return false
    end
    
    # check if user has pending status
    if @group.status(current_user) == 'pending'
      redirect_to :controller => "groups", 
        :action => 'join', :id => assignment.id
      return false
    end
    
    return true
  end
  
end
