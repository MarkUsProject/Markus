describe RolePolicy do
  let(:context) { { role: role, real_user: role.user } }
  describe_rule :manage? do
    succeed 'role is instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is student' do
      let(:role) { create(:student) }
    end
  end
end
