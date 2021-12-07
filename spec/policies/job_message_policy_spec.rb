describe JobMessagePolicy do
  let(:role) { create :admin }
  let(:context) { { role: role, real_user: role.human } }
  describe_rule :manage? do
    succeed
  end
end
