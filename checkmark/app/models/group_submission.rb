
class GroupSubmission < Submission
  
  belongs_to  :group
  
  # Return the user with the inviter status for this group
  def owner
    group.inviter
  end
  
end
