describe SubmissionPolicy do
  let(:real_user) { role.user }
  let(:context) { { role: role, real_user: real_user } }

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

  describe_rule :manage_subdirectories? do
    # role and user doesn't matter but needs to be set
    let(:role) { 1 }
    let(:real_user) { 1 }
    succeed
  end

  describe_rule :notebook_content? do
    # role and user doesn't matter but needs to be set
    let(:role) { 1 }
    let(:real_user) { 1 }
    succeed 'scanner dependencies are installed' do
      before { allow(Rails.application.config).to receive(:nbconvert_enabled).and_return(true) }
    end
    failed 'scanner dependencies are not installed' do
      before { allow(Rails.application.config).to receive(:nbconvert_enabled).and_return(false) }
    end
  end
end
