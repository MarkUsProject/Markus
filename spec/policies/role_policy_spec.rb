describe RolePolicy do
  let(:context) { { role: role, real_user: role.end_user } }
  describe_rule :manage? do
    succeed 'role is admin' do
      let(:role) { create :admin }
    end
    failed 'role is ta' do
      let(:role) { create :ta }
    end
    failed 'role is student' do
      let(:role) { create :student }
    end
  end
end
