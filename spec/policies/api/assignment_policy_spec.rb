describe Api::AssignmentPolicy do
  let(:user) { role.end_user }
  let(:context) { { role: role, real_user: user } }

  describe_rule :test_files? do
    succeed 'role is an instructor' do
      let(:role) { build :instructor }
    end
    succeed 'user is a test server' do
      let(:role) { nil }
      let(:user) { create :autotest_user }
    end
    failed 'role is a ta' do
      let(:role) { build :ta }
    end
    failed 'role is a student' do
      let(:role) { build :student }
    end
  end
end
