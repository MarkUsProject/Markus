class StudentMembership < Membership

  STATUSES = {
    :accepted => 'accepted',
    :inviter => 'inviter',
    :pending => 'pending',
    :rejected => 'rejected'
  }

  named_scope :accepted, :conditions => {:membership_status => STATUSES[:accepted]}
  named_scope :inviter, :conditions => {:membership_status => STATUSES[:inviter]}
  named_scope :pending, :conditions => {:membership_status => STATUSES[:pending]}
  named_scope :rejected, :conditions => {:membership_status => STATUSES[:rejected]}
  named_scope :accepted_or_inviter, :conditions => {:membership_status => [STATUSES[:accepted], STATUSES[:inviter]]}
  before_validation :must_be_valid_student

  validates_presence_of :membership_status
  validates_format_of :membership_status, :with => /inviter|pending|accepted|rejected/

  def must_be_valid_student
    if user && !user.is_a?(Student)
      errors.add_to_base("User must be a student")
      return false
    end
    if !STATUSES.values.include?(membership_status)
      errors.add_to_base("Invalid membership status")
      return false
    end
  end

  def inviter?
    return membership_status == 'inviter'
  end
end
