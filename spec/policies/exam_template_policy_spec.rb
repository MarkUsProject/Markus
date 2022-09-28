describe ExamTemplatePolicy do
  let(:context) { { role: role, real_user: role.user } }
  describe_rule :add_fields? do
    context 'role is an instructor' do
      let(:role) { create(:instructor) }
      succeed 'scanner dependencies are installed' do
        before { allow(Rails.application.config).to receive(:scanner_enabled).and_return(true) }
      end
      failed 'scanner dependencies are not installed' do
        before { allow(Rails.application.config).to receive(:scanner_enabled).and_return(false) }
      end
    end
    context 'role is a ta' do
      context 'that can manage assessments' do
        let(:role) { create :ta, manage_assessments: true }
        succeed 'scanner dependencies are installed' do
          before { allow(Rails.application.config).to receive(:scanner_enabled).and_return(true) }
        end
        failed 'scanner dependencies are not installed' do
          before { allow(Rails.application.config).to receive(:scanner_enabled).and_return(false) }
        end
      end
      failed 'that cannot manage assessments' do
        let(:role) { create :ta, manage_assessments: false }
      end
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end
  describe_rule :manage? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
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
