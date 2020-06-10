describe ResultPolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can delete grace period deduction' do
      it { is_expected.to pass :delete_grace_period_deduction? }
    end
  end
  describe 'When the user is TA' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    context 'When TA is allowed to delete grace period deduction' do
      before do
        create(:grader_permission, user_id: user.id, delete_grace_period_deduction: true)
      end
      it { is_expected.to pass :delete_grace_period_deduction? }
    end
    context 'When TA is not allowed to delete grace period deduction' do
      before do
        create(:grader_permission, user_id: user.id, delete_grace_period_deduction: false)
      end
      it { is_expected.not_to pass :delete_grace_period_deduction? }
    end
  end
end
