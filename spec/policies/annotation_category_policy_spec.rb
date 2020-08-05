describe AnnotationCategoryPolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can manage annotations and annotation categories' do
      it { is_expected.to pass :manage? }
    end
  end

  describe 'When the user is grader' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    let(:grader_permission) { user.grader_permission }
    context 'When the grader is allowed to manage annotations' do
      before do
        grader_permission.manage_assessments = true
        grader_permission.save
      end
      it { is_expected.to pass :manage? }
    end
    context 'When the grader is not allowed to manage annotations' do
      before do
        grader_permission.manage_assessments = false
        grader_permission.save
      end
      it { is_expected.not_to pass :manage? }
    end
  end
end
