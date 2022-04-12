describe UserPolicy do
  let(:context) { { real_user: user, user: user } }
  let(:user) { create :end_user }
  describe_rule :manage? do
    failed
  end
  describe_rule :destroy? do
    failed
  end

  describe_rule :reset_api_key? do
    failed
    succeed 'user is an instructor in at least one course' do
      let(:user) { create(:instructor).user }
    end
  end
  describe_rule :settings? do
    succeed
  end
  describe_rule :update_settings? do
    succeed
  end
end
