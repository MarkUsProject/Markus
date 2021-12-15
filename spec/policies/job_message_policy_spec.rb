describe JobMessagePolicy do
  let(:role) { create :instructor }
  let(:context) { { role: role, real_user: role.end_user } }
  describe_rule :manage? do
    succeed
  end
end
