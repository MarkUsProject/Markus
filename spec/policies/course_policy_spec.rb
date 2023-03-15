describe CoursePolicy do
  let(:context) { { role: role, real_user: role.user, user: role.user } }
  let(:role) { create :instructor }
  let(:record) { role&.course }
  describe_rule :show? do
    succeed 'role is an instructor'
    succeed 'role is a ta' do
      let(:role) { create :ta }
    end
    succeed 'role is a student' do
      let(:role) { create :student }
    end
    failed 'role is nil' do
      let(:context) { { role: role, real_user: create(:end_user) } }
      let(:role) { nil }
    end
  end
  describe_rule :index? do
    succeed 'role is an end user'
    failed 'user is an adminuser' do
      let(:role) { create :admin_role }
    end
  end
  describe_rule :manage_lti_deployments? do
    succeed 'role is an instructor'
    succeed 'user is an admin' do
      let(:role) { create :admin_role }
    end
    failed 'role is a grader' do
      let(:role) { create :ta }
    end
    failed 'role is a student' do
      let(:role) { create :student }
    end
  end
end
