describe CoursePolicy do
  let(:context) { { role: role, real_user: role.user, user: role.user } }
  let(:role) { create :instructor }
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
  describe_rule :destroy_lti_deployment? do
    succeed 'role is an instructor'
    succeed 'role is an admin role' do
      let(:role) { create :admin_role }
    end
    failed 'user is a grader' do
      let(:role) { create :ta }
    end
    failed 'user is a student' do
      let(:role) { create :student }
    end
  end
end
