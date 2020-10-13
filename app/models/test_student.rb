# TestStudent - fake student, used for running tests on solution files
class TestStudent < User
  has_many :accepted_groupings, lambda {
    where 'memberships.membership_status' =>
              [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]]
  },
           class_name: 'Grouping',
           through: :memberships,
           source: :grouping

  has_many :student_memberships, foreign_key: 'user_id'
  validates_associated :accepted_groupings

  def validate_membership_status
    membership = memberships.find_by(user_id: self.id)
    return true if membership.membership_status == 'inviter'
    errors.add(:base, 'A test student can only be an inviter')
    false
  end

  def validate_grouping_member(grouping)
    members = grouping.memberships.count
    return true if members == 1
    errors.add(:base, 'Grouping with test student should have no other members')
    false
  end
end
