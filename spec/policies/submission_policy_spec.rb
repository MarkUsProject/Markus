describe SubmissionPolicy do
  include PolicyHelper

  describe '#run_tests?' do
    subject { described_class.new(submission, user: user) }

    context 'when the user is an admin' do
      let(:user) { build(:admin) }

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

    context 'when the user is a student' do
      let(:user) { build(:student) }
      let(:submission) { build_stubbed(:submission) }
      it { is_expected.not_to pass :run_tests?, because_of: :not_a_student? }
    end
  end

  describe '#get_feedback_file?' do
    subject { described_class.new(submission, user: user) }

    context 'when the user is an admin' do
      let(:user) { create(:admin) }
      let(:submission) { create(:submission) }

      it { is_expected.to pass :get_feedback_file? }
    end

    context 'when the user is a TA' do
      let(:user) { create(:ta) }
      let(:submission) { create(:submission) }

      context 'who is assigned to the grouping' do
        let!(:membership) { create(:ta_membership, user: user, grouping: submission.grouping) }
        it { is_expected.to pass :get_feedback_file? }
      end

      context 'who is not assigned to the grouping' do
        it { is_expected.not_to pass :get_feedback_file? }
      end
    end

    context 'when the user is a student' do
      let(:user) { create(:student) }
      let(:result) { create(:complete_result) }
      let(:submission) { result.submission }

      context 'who is not part of the grouping' do
        it { is_expected.not_to pass :get_feedback_file? }
      end

      context 'when the submission result is not released' do
        before do
          submission = result.submission
          create(:accepted_student_membership, grouping: submission.grouping, user: user)
          result.update!(released_to_students: false)
        end
        it { is_expected.not_to pass :get_feedback_file? }
      end

      context 'when the submission result is released' do
        before do
          submission = result.submission
          create(:accepted_student_membership, grouping: submission.grouping, user: user)
          result.update!(released_to_students: true)
        end
        it { is_expected.to pass :get_feedback_file? }
      end
    end
  end
end
