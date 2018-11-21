describe SubmissionPolicy do
  include PolicyHelper

  describe '#run_tests?' do

    context 'when the user is an admin' do
      context 'if the assignment policy fails' do
        it do
          user = build_stubbed(:admin)
          submission = build_stubbed(:submission)
          expect(policy(submission, user)).not_to pass :run_tests?, because_of: { AssignmentPolicy => :run_tests? }
        end
      end
      context 'if the assignment policy passes' do
        context 'if marks are released' do
          it do
            user = build_stubbed(:admin)
            assignment = create(:assignment_for_instructor_tests)
            grouping = create(:grouping, assignment: assignment)
            submission = create(:submission, grouping: grouping)
            result = submission.current_result # a submission after_create callback created the result
            result.marking_state = Result::MARKING_STATES[:complete]
            result.released_to_students = true
            result.save!
            expect(policy(submission, user)).not_to pass :run_tests?, because_of: :before_release?
          end
        end
        context 'if marks are not released' do
          it do
            user = build_stubbed(:admin)
            assignment = create(:assignment_for_instructor_tests)
            grouping = create(:grouping, assignment: assignment)
            submission = create(:submission, grouping: grouping)
            expect(policy(submission, user)).to pass :run_tests?
          end
        end
      end
    end

    context 'when the user is a TA' do
      it do
        user = build_stubbed(:ta)
        submission = build_stubbed(:submission)
        expect(policy(submission, user)).not_to pass :run_tests?, because_of: { AssignmentPolicy => :run_tests? }
      end
    end

    context 'when the user is a student' do
      it do
        user = build_stubbed(:student)
        submission = build_stubbed(:submission)
        expect(policy(submission, user)).not_to pass :run_tests?, because_of: :not_a_student?
      end
    end
  end
end
