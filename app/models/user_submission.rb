
class UserSubmission < Submission
  
  belongs_to  :user
  
  def owner
    return user
  end
  
end
