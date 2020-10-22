describe StudentPolicy do
  let(:user) { create :student }
  let(:context) { { user: user } }

  describe_rule :run_tests? do
    failed 'with not additional context'
    context 'authorized with an assignment' do
      let(:context) { { user: user, assignment: assignment } }
      let(:assignment) { create :assignment, assignment_properties_attributes: assignment_attrs }
      failed 'without student tests enabled' do
        let(:assignment_attrs) { { token_start_date: 1.hour.ago, enable_student_tests: false } }
      end
      failed 'when tokens have not been released yet' do
        let(:assignment_attrs) { { token_start_date: 1.hour.from_now, enable_student_tests: true } }
      end
      context 'when student tests are enabled and tokens have been released' do
        succeed 'when there are tokens' do
          let(:assignment_attrs) { { token_start_date: 1.hour.ago, enable_student_tests: true, tokens_per_period: 1 } }
        end
        succeed 'when there are unlimited tokens' do
          let(:assignment_attrs) do
            { token_start_date: 1.hour.ago, enable_student_tests: true, unlimited_tokens: true }
          end
        end
        failed 'when there are no tokens available' do
          let(:assignment_attrs) { { token_start_date: 1.hour.ago, enable_student_tests: true } }
        end
      end
    end
    context 'authorized with a grouping' do
      let(:context) { { user: user, grouping: grouping } }
      succeed 'when the user is a member' do
        let(:grouping) { create :grouping_with_inviter, inviter: user, test_tokens: 1 }
        failed 'when there is a test in progress' do
          before { allow(grouping).to receive(:student_test_run_in_progress?).and_return true }
        end
        failed 'when there are no tokens available' do
          let(:grouping) { create :grouping_with_inviter, inviter: user, test_tokens: 0 }
        end
        failed 'when the due date has passed' do
          let(:assignment) { create :assignment, due_date: 1.day.ago }
          let(:grouping) { create :grouping_with_inviter, assignment: assignment, inviter: user, test_tokens: 1 }
        end
      end
      failed 'when the user is not a member' do
        let(:grouping) { create :grouping_with_inviter, test_tokens: 1 }
      end
    end
    context 'authorized with a submission' do
      let(:context) { { user: user, submission: result.submission } }
      failed 'with a released result' do
        let(:result) { create :released_result }
      end
      succeed 'with a non-release result' do
        let(:result) { create :complete_result }
      end
    end
  end
  describe_rule :manage_submissions? do
    failed
  end
  describe_rule :manage_assessments? do
    failed
  end
end
