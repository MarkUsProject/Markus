describe MarkingSchemePolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can manage marking schemes' do
      it { is_expected.to pass :manage? }
    end
  end
  describe 'When the user is TA' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    context 'When TA is allowed to manage marking schemes' do
      before do
        user.grader_permission.manage_marking_schemes = true
        user.grader_permission.save
      end
      it { is_expected.to pass :manage? }
    end
    context 'When TA is not allowed to manage automated testing' do
      before do
        user.grader_permission.manage_marking_schemes = false
        user.grader_permission.save
      end
      it { is_expected.not_to pass :manage? }
    end
  end
end
