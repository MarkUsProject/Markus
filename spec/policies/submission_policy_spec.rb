describe SubmissionPolicy do
  include PolicyHelper

  describe '#run_tests?' do
    subject { described_class.new(submission, user: user) }

    context 'when the user is an admin' do
      let(:user) { build(:admin) }

      context 'if the assignment policy fails' do
        let(:submission) { build_stubbed(:submission) }
        it { is_expected.not_to pass :run_tests?, because_of: { AssignmentPolicy => :run_tests? } }
      end

      context 'if the assignment policy passes' do
        let(:assignment) { create(:assignment_for_tests) }
        let(:grouping) { create(:grouping, assignment: assignment) }
        let(:submission) { create(:submission, grouping: grouping) }

        context 'if marks are released' do
          before do
            result = submission.current_result # a submission after_create callback created the result
            result.marking_state = Result::MARKING_STATES[:complete]
            result.released_to_students = true
            result.save!
          end
          it { is_expected.not_to pass :run_tests?, because_of: :before_release? }
        end

        context 'if marks are not released' do
          it { is_expected.to pass :run_tests? }
        end
      end
    end

    context 'when the user is a TA' do
      let(:user) { build(:ta) }
      let(:submission) { build_stubbed(:submission) }
      it { is_expected.not_to pass :run_tests?, because_of: { AssignmentPolicy => :run_tests? } }
    end

    context 'when the user is a student' do
      let(:user) { build(:student) }
      let(:submission) { build_stubbed(:submission) }
      it { is_expected.not_to pass :run_tests?, because_of: :not_a_student? }
    end
  end
end
