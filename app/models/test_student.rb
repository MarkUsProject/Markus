class TestStudent < User
  after_create :create_associations

  def create_associations
    assignment_ids = Assignment.pluck(:id)
    group = Group.create!(group_name: 'test_student_groups')
    grouping = Grouping.create!(group_id: group.id, assessment_id: assignment_ids[0])
    self.add_member(self, grouping)
    Submission.create!(grouping_id: grouping.id, submission_version: 1)
  end

  def add_member(user, grouping, set_membership_status = StudentMembership::STATUSES[:accepted])
    StudentMembership.create!(user: user, membership_status:
        set_membership_status, grouping: grouping)
  end
end
