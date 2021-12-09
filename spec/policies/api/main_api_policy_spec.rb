describe Api::MainApiPolicy do
  let(:user) { role.end_user }
  let(:context) { { role: role, real_user: user } }

  describe_rule :manage? do
    succeed 'role is an admin' do
      let(:role) { build :admin }
    end
    failed 'user is a test server' do
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
