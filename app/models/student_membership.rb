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
  validate :one_accepted_per_assignment

  validates_presence_of :membership_status
  validates_format_of :membership_status,
                      with: /\Ainviter|pending|accepted|rejected\z/

  after_save :update_repo_permissions_after_save
  after_create :update_repo_permissions_after_create
  after_destroy :update_repo_permissions_after_destroy

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

  def update_repo_permissions_after_create
    return unless grouping.assignment.vcs_submit
    return if [STATUSES[:pending], STATUSES[:rejected]].include?(membership_status)
    Repository.get_class.update_permissions
  end

  def update_repo_permissions_after_destroy
    return unless grouping.assignment.vcs_submit
    return if [STATUSES[:pending], STATUSES[:rejected]].include?(membership_status)
    return if grouping.group.assignments.count > 1
    Repository.get_class.update_permissions
  end

  def update_repo_permissions_after_save
    return unless grouping.assignment.vcs_submit
    return unless saved_change_to_attribute? :membership_status
    old, new = saved_change_to_attribute :membership_status
    access = [STATUSES[:accepted], STATUSES[:inviter]]
    no_access = [STATUSES[:pending], STATUSES[:rejected]]
    if access.include?(old) && no_access.include?(new) || access.include?(new) && no_access.include?(old)
       Repository.get_class.update_permissions
    end
  end

  # Raises an error if this user already has an accepted membership for a different grouping for this assignment
  def one_accepted_per_assignment
    return unless user.try(:student?)

    all_memberships = user.accepted_memberships
                          .joins(:grouping)
                          .where('groupings.assessment_id': grouping.assessment_id)
    return if all_memberships.empty? || all_memberships.find_by(id: self.id)

    errors.add(:base, I18n.t('csv.memberships_not_unique'))
    throw(:abort)
  end
end
