describe ExamTemplatePolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can manage exam templates' do
      it { is_expected.to pass :manage? }
    end
    context 'Admin can edit, update, download, destroy exam templates' do
      it { is_expected.to pass :modify? }
    end
  end
  describe 'When the user is TA' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    context 'When TA is allowed to edit, update, download, destroy exam templates' do
      before do
        user.grader_permission.manage_assessments = true
        user.grader_permission.save
      end
      it { is_expected.to pass :modify? }
    end
    context 'When TA is not allowed to edit, update, download, destroy exam templates' do
      before do
        user.grader_permission.manage_assessments = false
        user.grader_permission.save
      end
      it { is_expected.not_to pass :modify? }
    end
    context 'TA cannot manage exam templates' do
      it { is_expected.not_to pass :manage? }
    end
  end
end
