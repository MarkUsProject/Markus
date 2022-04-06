describe SubmissionPolicy do
  let(:context) { { role: role, real_user: role.user } }

  describe_rule :manage? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
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
    failed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :run_tests? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      succeed 'that can run tests' do
        let(:role) { create :ta, run_tests: true }
      end
      failed 'that cannot run tests' do
        let(:role) { create :ta, run_tests: false }
      end
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end
end
