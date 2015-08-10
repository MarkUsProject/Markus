class StudentMembership < Membership

  STATUSES = {
    accepted: 'accepted',
    inviter: 'inviter',
    pending: 'pending',
    rejected: 'rejected'
  }

  scope :accepted,
        -> { where membership_status: STATUSES[:accepted] }
  scope :inviter,
        -> { where membership_status: STATUSES[:inviter] }
  scope :pending,
        -> { where membership_status: STATUSES[:pending] }
  scope :rejected,
        -> { where membership_status: STATUSES[:rejected] }
  scope :accepted_or_inviter,
        -> { where membership_status: [STATUSES[:accepted], STATUSES[:inviter]] }

  validate :must_be_valid_student

  validates_presence_of :membership_status
  validates_format_of :membership_status,
                      with: /inviter|pending|accepted|rejected/

  def must_be_valid_student
    if user && !user.is_a?(Student)
      errors.add('base', 'User must be a student')
      return false
    end
    unless STATUSES.values.include?(membership_status)
      errors.add('base', 'Invalid membership status')
      false
    end
  end

  def inviter?
    membership_status == 'inviter'
  end
end
