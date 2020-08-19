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
    context 'When the grader is allowed to manage annotations' do
      let(:user) { create(:ta, manage_assessments: true) }
      it { is_expected.to pass :manage? }
    end
    context 'When the grader is not allowed to manage annotations' do
      it { is_expected.not_to pass :manage? }
    end
  end
end
