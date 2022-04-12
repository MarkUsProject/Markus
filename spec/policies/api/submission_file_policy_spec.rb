describe Api::SubmissionFilePolicy do
  let(:user) { role.user }
  let(:role) { nil }
  let(:context) { { role: role, real_user: user } }

  describe_rule :index? do
    succeed 'user is an admin user' do
      let(:user) { build :admin_user }
    end
    succeed 'role is an instructor' do
      let(:role) { build :instructor }
    end
    succeed 'user is a test server' do
      let(:user) { build :autotest_user }
      let(:role) { nil }
    end
    failed 'role is a ta' do
      let(:role) { build :ta }
    end
    failed 'role is a student' do
      let(:role) { build :student }
    end
  end
end
