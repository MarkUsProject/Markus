describe AnnotationPolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can manage annotations' do
      it { is_expected.to pass :manage? }
    end
    context 'Admin can add existing annotation' do
      it { is_expected.to pass :add_existing_annotation? }
    end
  end
  describe 'When the user is grader' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    context 'Grader can add existing annotation' do
      it { is_expected.to pass :add_existing_annotation? }
    end
    context 'When grader is allowed to manage annotations' do
      before do
        user.grader_permission.create_delete_annotations = true
        user.grader_permission.save
      end
      it { is_expected.to pass :manage? }
    end
    context 'When grader is not allowed to manage annotations' do
      before do
        user.grader_permission.create_delete_annotations = false
        user.grader_permission.save
      end
      it { is_expected.not_to pass :manage? }
    end
  end
  describe 'When the user is student' do
    subject { described_class.new(user: user) }
    context 'Student cannot add existing annotation' do
      let(:user) { create(:student) }
      it { is_expected.not_to pass :add_existing_annotation? }
    end
    context 'When the student is doing peer reviews' do
      subject { described_class.new(result, user: reviewer) }
      let(:reviewee) { create(:student) }
      let(:reviewer) { create(:student) }
      let(:assignment) { create(:assignment_with_peer_review) }
      let(:grouping_one) { create(:grouping_with_inviter, assignment: assignment, inviter: reviewee) }
      let(:submission) { create(:submission, grouping: grouping_one) }
      let(:result) { create(:incomplete_result, submission: submission) }
      let(:grouping_two) { create(:grouping_with_inviter, assignment: assignment.pr_assignment, inviter: reviewer) }
      let!(:peer_review) { create(:peer_review, result: result, reviewer: grouping_two) }
      describe 'When assignment has peer review and student is reviewer for that assignment' do
        it 'should pass manage' do
          is_expected.to pass :manage?
        end
      end
      describe 'When assignment has peer review and student is not a reviewer for that assignment' do
        let(:reviewer_two) { create(:student) }
        let(:grouping_three) do
          create(:grouping_with_inviter, assignment: assignment.pr_assignment, inviter: reviewer_two)
        end
        before do
          peer_review.reviewer = grouping_three
          peer_review.save
        end
        it 'should pass manage' do
          is_expected.not_to pass :manage?
        end
      end
    end
  end
end
