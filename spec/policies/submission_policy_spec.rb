describe SubmissionPolicy do
  let(:context) { { role: role, real_user: role.human } }

  describe_rule :manage? do
    succeed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    context 'role is a ta' do
      succeed 'that can manage submissions' do
        let(:role) { create :ta, manage_submissions: true }
      end
      failed 'that cannot manage submissions' do
        let(:role) { create :ta, manage_submissions: false }
      end
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :file_manager? do
    failed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:role) { create(:student) }
    end
  end
end
