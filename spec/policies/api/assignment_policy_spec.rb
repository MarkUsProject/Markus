describe Api::AssignmentPolicy do
  let(:user) { role.user }
  let(:role) { nil }
  let(:context) { { role: role, real_user: user } }

  describe_rule :test_files? do
    succeed 'user is an admin user' do
      let(:user) { build :admin_user }
    end
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

  describe_rule :submit_file? do
    succeed 'user is an admin user' do
      let(:user) { build :admin_user }
    end
    failed 'role is an instructor' do
      let(:role) { build :instructor }
    end
    failed 'user is a test server' do
      let(:user) { build :autotest_user }
      let(:role) { nil }
    end
    failed 'role is a ta' do
      let(:role) { build :ta }
    end
    succeed 'role is a student' do
      let(:role) { build :student }
    end
  end

  describe_rule :index? do
    succeed 'user is an admin user' do
      let(:user) { build :admin_user }
    end
    succeed 'role is an instructor' do
      let(:role) { create :instructor }
    end
    failed 'user is a test server' do
      let(:role) { nil }
      let(:user) { create :autotest_user }
    end
    succeed 'role is a ta' do
      let(:role) { create :ta }
    end
    succeed 'role is a student' do
      let(:role) { create :student }
    end
  end
end
