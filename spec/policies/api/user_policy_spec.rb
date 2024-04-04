describe Api::UserPolicy do
  let(:context) { { real_user: user } }

  describe_rule :manage? do
    succeed 'user is an admin user' do
      let(:user) { build(:admin_user) }
    end
    failed 'user is a end user' do
      let(:user) { build(:end_user) }
    end
    failed 'user is an autotest user' do
      let(:user) { build(:autotest_user) }
    end
  end
end
