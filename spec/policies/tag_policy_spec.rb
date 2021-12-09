describe TagPolicy do
  let(:context) { { role: role, real_user: role.end_user } }
  describe_rule :manage? do
    succeed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end
end
