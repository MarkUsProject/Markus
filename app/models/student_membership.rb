class StudentMembership < Membership
  STATUSES = { 
    :accepted => 'accepted', 
    :inviter => 'inviter', 
    :pending => 'pending', 
    :rejected => 'rejected'
  }

  validates_presence_of :membership_status
  validates_format_of :membership_status, :with => /inviter|pending|accepted|rejected/

  def validate
      errors.add_to_base("User must be a student") if user && !user.is_a?(Student)
      errors.add_to_base("Invalid membership status") if !STATUSES.values.include?(membership_status)
  end
  
  def inviter?
    return membership_status == 'inviter'
  end
end
