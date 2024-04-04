describe UserPolicy do
  let(:context) { { real_user: user, user: user } }
  let(:user) { 1 } # user doesn't actually matter for any of these policies but needs to be set
  describe_rule :manage? do
    failed
  end
  describe_rule :destroy? do
    failed
  end

  describe_rule :reset_api_key? do
    succeed
  end
  describe_rule :settings? do
    succeed
  end
  describe_rule :update_settings? do
    succeed
  end
  describe_rule :lti_manage? do
    let(:context) { { real_user: role.user, user: role.user, role: role } }
    succeed 'role is instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is student' do
      let(:role) { create(:student) }
    end
    context 'as an admin user' do
      let(:context) { { real_user: user, user: user } }
      succeed 'user is an admin user' do
        let(:user) { create(:admin_user) }
      end
    end
  end
end
