describe JobMessagePolicy do
  let(:role) { create(:instructor) }
  let(:context) { { role: role, real_user: role.user } }
  describe_rule :manage? do
    succeed
  end
end
