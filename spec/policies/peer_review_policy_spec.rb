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
        user.grader_permission.manage_reviewers = true
        user.grader_permission.save
      end
      it { is_expected.to pass :assign_reviewers? }
    end
    context 'When TA is not allowed to assign or unassign reviewers' do
      before do
        user.grader_permission.manage_reviewers = false
        user.grader_permission.save
      end
      it { is_expected.not_to pass :assign_reviewers? }
    end
  end
end
