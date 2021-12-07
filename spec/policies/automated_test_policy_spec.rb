describe AutomatedTestPolicy do
  let(:context) { { role: role, real_user: role.human } }
  describe_rule :manage? do
    succeed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    context 'role is a ta' do
      succeed 'that can manage assessments' do
        let(:role) { create :ta, manage_assessments: true }
      end
      failed 'that cannot manage assessments' do
        let(:role) { create :ta, manage_assessments: false }
      end
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end
end
