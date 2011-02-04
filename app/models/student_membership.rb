class StudentMembership < Membership
 
  STATUSES = { 
    :accepted => 'accepted', 
    :inviter => 'inviter', 
    :pending => 'pending', 
    :rejected => 'rejected'
  }
  
  scope :accepted, :conditions => {:membership_status => STATUSES[:accepted]}
  scope :inviter, :conditions => {:membership_status => STATUSES[:inviter]}
  scope :pending, :conditions => {:membership_status => STATUSES[:pending]}
  scope :rejected, :conditions => {:membership_status => STATUSES[:rejected]}
  scope :accepted_or_inviter, :conditions => {:membership_status => [STATUSES[:accepted], STATUSES[:inviter]]}
  
  validates_presence_of :membership_status
  validates_format_of :membership_status, :with => /inviter|pending|accepted|rejected/

  def validate
      errors.add(:base, "User must be a student") if user && !user.is_a?(Student)
      errors.add(:base, "Invalid membership status") if !STATUSES.values.include?(membership_status)
  end
  
  def inviter?
    return membership_status == 'inviter'
  end
end
