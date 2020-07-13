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
    context 'When the grader is allowed to manage assignments and also annotations' do
      before do
        create(:grader_permission, user_id: user.id, create_delete_annotations: true, manage_assignments: true)
      end
      it { is_expected.to pass :manage? }
    end
    context 'When the grader is allowed to manage assignments but not annotations' do
      before do
        create(:grader_permission, user_id: user.id, create_delete_annotations: false, manage_assignments: true)
      end
      it { is_expected.not_to pass :manage? }
    end
    context 'When the grader is allowed to manage annotations but not assignments' do
      before do
        create(:grader_permission, user_id: user.id, create_delete_annotations: true, manage_assignments: false)
      end
      it { is_expected.not_to pass :manage? }
    end
  end
end
