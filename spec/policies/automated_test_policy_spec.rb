describe AutomatedTestPolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can manage automated testing' do
      it { is_expected.to pass :manage? }
    end
    context 'Admin cannot access the student interface' do
      it { is_expected.not_to pass :student_access? }
    end
  end
  describe 'When the user is TA' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    context 'When TA is allowed to manage automated testing' do
      before do
        user.grader_permission.manage_assignments = true
        user.grader_permission.save
      end
      it { is_expected.to pass :manage? }
    end
    context 'When TA is not allowed to manage automated testing' do
      before do
        user.grader_permission.manage_assignments = false
        user.grader_permission.save
      end
      it { is_expected.not_to pass :manage? }
    end
    context 'TA cannot access the student interface' do
      it { is_expected.not_to pass :student_access? }
    end
  end
  describe 'When the user is student' do
    subject { described_class.new(user: user) }
    let(:user) { build(:student) }
    context 'Student cannot manage automated testing' do
      it { is_expected.not_to pass :manage? }
    end
    context 'Student can access student interface and execute test run' do
      it { is_expected.to pass :student_access? }
    end
  end
end
