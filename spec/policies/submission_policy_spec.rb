describe SubmissionPolicy do
  include PolicyHelper

  describe '#run_tests?' do

    context 'when the user is an admin' do
      context 'if AssignmentPolicy#run_tests? returns false' do
        it do
          user = build(:admin)
          submission = build_stubbed(:submission)
          expect(apply_policy(submission, user, :run_tests?)).to be false
        end
      end
      context 'if AssignmentPolicy#run_tests? returns true' do
        context 'if marks are released' do
          it do
            user = build(:admin)
            submission = create(:submission)
            result = submission.current_result # a submission after_create callback created the result
            result.marking_state = Result::MARKING_STATES[:complete]
            result.released_to_students = true
            result.save!
            expect(apply_policy(submission, user, :run_tests?)).to be false
          end
        end
        context 'if marks are not released' do
          it do
            user = build(:admin)
            submission = create(:submission)
            expect(apply_policy(submission, user, :run_tests?)).to be true
          end
        end
      end
    end

    context 'when the user is a TA' do
      it do
        user = build(:ta)
        submission = build_stubbed(:submission)
        expect(apply_policy(submission, user, :run_tests?)).to be false
      end
    end

    context 'when the user is a student' do
      it do
        user = build(:student)
        submission = build_stubbed(:submission)
        expect(apply_policy(submission, user, :run_tests?)).to be false
      end
    end
  end
end
