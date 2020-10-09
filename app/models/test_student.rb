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
end
