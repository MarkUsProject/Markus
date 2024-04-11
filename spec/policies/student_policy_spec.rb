describe StudentPolicy do
  let(:role) { create(:student) }
  let(:context) { { role: role, real_user: role.user } }

  describe_rule :run_tests? do
    failed 'with not additional context'
    context 'authorized with an assignment' do
      let(:context) { { role: role, assignment: assignment, real_user: role.user } }
      let(:assignment) { create(:assignment, assignment_properties_attributes: assignment_attrs) }
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
      let(:context) { { role: role, grouping: grouping, real_user: role.user } }
      succeed 'when the role is a member' do
        let(:grouping) { create(:grouping_with_inviter, inviter: role, test_tokens: 1) }
        failed 'when there is a test in progress' do
          before { allow(grouping).to receive(:student_test_run_in_progress?).and_return true }
        end
        failed 'when there are no tokens available' do
          let(:grouping) { create(:grouping_with_inviter, inviter: role, test_tokens: 0) }
        end
      end
      failed 'when the role is not a member' do
        let(:grouping) { create(:grouping_with_inviter, test_tokens: 1) }
      end
    end
    context 'authorized with a grouping and an assignment' do
      let(:context) { { role: role, grouping: grouping, assignment: assignment, real_user: role.user } }
      let(:assignment) do
        create(:assignment, due_date: assign_due_date, assignment_properties_attributes: assignment_attrs)
      end
      failed 'when the due date has passed and token end date is nil' do
        let(:assign_due_date) { 1.hour.ago }
        let(:assignment_attrs) do
          { token_start_date: 2.hours.ago, token_end_date: nil,
            enable_student_tests: true, unlimited_tokens: true }
        end
        let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: role) }
      end
      succeed 'when the token end date has not passed' do
        let(:assign_due_date) { 2.hours.from_now }
        let(:assignment_attrs) do
          { token_start_date: 2.hours.ago, token_end_date: 1.hour.from_now,
            enable_student_tests: true, unlimited_tokens: true }
        end
        let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: role) }
      end
      failed 'when the token end date has passed' do
        let(:assign_due_date) { 2.hours.from_now }
        let(:assignment_attrs) do
          { token_start_date: 2.hours.ago, token_end_date: 1.hour.ago,
            enable_student_tests: true, unlimited_tokens: true }
        end
        let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: role) }
      end
    end
    context 'authorized with a submission' do
      let(:context) { { role: role, submission: result.submission, real_user: role.user } }
      failed 'with a released result' do
        let(:result) { create(:released_result) }
      end
      succeed 'with a non-release result' do
        let(:result) { create(:complete_result) }
      end
    end
  end
  describe_rule :manage_submissions? do
    failed
  end
  describe_rule :manage_assessments? do
    failed
  end
  describe_rule :settings? do
    failed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:record) { create(:student) }
    end
  end

  describe_rule :manage_role_status? do
    let(:context) { { role: role, real_user: role.user, user: role.user } }
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
    succeed 'user is an admin' do
      let(:role) { create(:admin_role) }
    end
  end

  describe_rule :can_cancel_test? do
    let(:context) { { role: role, test_run_id: test_run_id, real_user: role.user } }
    context 'when test run created by student' do
      let(:role) { create(:student) }
      succeed 'test in progress' do
        let(:test_run) { create(:student_test_run, role: role, status: :in_progress) }
        let(:test_run_id) { test_run.id }
      end
      failed 'test not in progress' do
        let(:test_run) { create(:student_test_run, role: role, status: :complete) }
        let(:test_run_id) { test_run.id }
      end
    end
    failed 'test not created by student' do
      let(:test_run) { create(:student_test_run, status: :in_progress) }
      let(:test_run_id) { test_run.id }
    end
  end
end
