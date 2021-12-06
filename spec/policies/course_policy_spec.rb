describe CoursePolicy do
  let(:course) { create :course, is_hidden: false }
  let(:context) { { role: role, real_user: role.human } }
  let(:role) { create :student, course: course }
  describe_rule :show? do
    succeed
  end
  describe_rule :index? do
    succeed
  end
end
