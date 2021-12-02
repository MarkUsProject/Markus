describe MarkingSchemePolicy do
  let(:context) { { role: role, real_user: role.human } }
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
