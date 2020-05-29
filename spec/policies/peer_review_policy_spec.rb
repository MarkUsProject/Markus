describe PeerReviewPolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can assign or unassign reviewers' do
      it { is_expected.to pass :assign_reviewers? }
    end
  end
  describe 'When the user is TA' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    context 'When TA is allowed to assign or unassign reviewers' do
      before do
        create(:grader_permissions, user_id: user.id, manage_reviewers: true)
      end
      it { is_expected.to pass :assign_reviewers? }
    end
    context 'When TA is not allowed to assign or unassign reviewers' do
      before do
        create(:grader_permissions, user_id: user.id, manage_reviewers: false)
      end
      it { is_expected.not_to pass :assign_reviewers? }
    end
  end
end
