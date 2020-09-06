describe PeerReviewPolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can manage reviewers' do
      it { is_expected.to pass :manage_reviewers? }
    end
    context 'Admin can manage peer reviews' do
      it { is_expected.to pass :manage? }
    end
  end
  describe 'When the user is grader' do
    subject { described_class.new(user: user) }
    # By default all the grader permissions are set to false
    let(:user) { create(:ta) }
    context 'When grader is allowed to manage reviewers' do
      let(:user) { create(:ta, manage_assessments: true) }
      it { is_expected.to pass :manage_reviewers? }
    end
    context 'When grader is not allowed to assign or unassign reviewers' do
      it { is_expected.not_to pass :manage_reviewers? }
    end
    context 'Grader cannot manage peer reviews' do
      it { is_expected.not_to pass :manage? }
    end
  end
end
