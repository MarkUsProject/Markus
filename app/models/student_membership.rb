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
                      with: /\Ainviter|pending|accepted|rejected\z/

  before_update :update_repo_permissions_before_update
  before_create :update_repo_permissions_before_create
  before_destroy :update_repo_permissions_before_destroy

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

  private

  def update_repo_permissions_before_create
    return unless grouping.assignment.read_attribute(:vcs_submit)
    return if [STATUSES[:pending], STATUSES[:rejected]].include?(membership_status)
    Repository.get_class.update_permissions
  end

  def update_repo_permissions_before_destroy
    return unless grouping.assignment.read_attribute(:vcs_submit)
    return if [STATUSES[:pending], STATUSES[:rejected]].include?(membership_status)
    return if grouping.group.assignments.count > 1
    Repository.get_class.update_permissions
  end

  def update_repo_permissions_before_update
    return unless grouping.assignment.read_attribute(:vcs_submit)
    return unless membership_status_changed?
    old, new = membership_status_change
    access = [STATUSES[:accepted], STATUSES[:inviter]]
    no_access = [STATUSES[:pending], STATUSES[:rejected]]
    if access.include?(old) && no_access.include?(new) || access.include?(new) && no_access.include?(old)
       Repository.get_class.update_permissions
    end
  end
end
