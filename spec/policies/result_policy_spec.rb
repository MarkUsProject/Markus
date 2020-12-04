describe ResultPolicy do
  let(:context) { { user: user } }

  describe_rule :view? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    succeed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    succeed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :run_tests? do
    let(:record) { create :complete_result, submission: submission }
    let(:submission) { create :submission, grouping: grouping }
    let(:grouping) { create :grouping, assignment: assignment }
    let(:assignment) { create :assignment }
    context 'user is an admin' do
      let(:user) { create :admin }
      failed 'when result is released' do
        let(:record) { create :released_result }
      end
      context 'when result is not released' do
        failed 'without tests enabled' do
          let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: false } }
        end
        context 'with test enabled' do
          let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: true } }
          succeed 'with test groups' do
            let!(:test_group) { create :test_group, assignment: assignment }
          end
          failed 'without test groups'
        end
      end
    end
    context 'user is a ta' do
      failed 'without run test permissions' do
        let(:user) { create :ta, run_tests: false }
      end
      context 'with run test permissions' do
        let(:user) { create :ta, run_tests: true }
        failed 'when result is released' do
          let(:record) { create :released_result }
        end
        context 'when result is not released' do
          failed 'without tests enabled' do
            let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: false } }
          end
          context 'with test enabled' do
            let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: true } }
            succeed 'with test groups' do
              let!(:test_group) { create :test_group, assignment: assignment }
            end
            failed 'without test groups'
          end
        end
      end
    end
    context 'user is a student' do
      let(:user) { create :student }
      let(:assignment) { create :assignment, assignment_properties_attributes: assignment_attrs }
      let(:assignment_attrs) { {} }
      context 'when the user is a member of the grouping' do
        let(:grouping) { create :grouping_with_inviter, assignment: assignment, inviter: user, test_tokens: 1 }
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
        failed 'with a released result' do
          let(:result) { create :released_result }
        end
        context 'with a non-released result' do
          failed 'without student tests enabled' do
            let(:assignment_attrs) { { token_start_date: 1.hour.ago, enable_student_tests: false } }
          end
          failed 'when tokens have not been released yet' do
            let(:assignment_attrs) { { token_start_date: 1.hour.from_now, enable_student_tests: true } }
          end
          context 'when student tests are enabled and tokens have been released' do
            succeed 'when there are tokens' do
              let(:assignment_attrs) do
                { token_start_date: 1.hour.ago, enable_student_tests: true, tokens_per_period: 1 }
              end
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
      end
      failed 'when the user is not a member of the grouping' do
        let(:grouping) { create :grouping_with_inviter, test_tokens: 1 }
      end
    end
  end

  describe_rule :grade? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    succeed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :review? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    succeed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    context 'user is a student' do
      let(:user) { create(:student) }
      let(:record) { create :complete_result, submission: create(:submission, grouping: grouping) }
      let(:grouping) { create :grouping_with_inviter, inviter: user, assignment: assignment }
      context 'when the assignment has a peer review' do
        let(:assignment) { create :assignment_with_peer_review }
        succeed 'when the user is a reviewer for the result' do
          let(:record) { create :complete_result, submission: create(:submission, grouping: review_grouping) }
          let(:grouping) { create :grouping_with_inviter, inviter: user, assignment: assignment.pr_assignment }
          let(:review_grouping) { create :grouping_with_inviter, assignment: assignment }
          before { create :peer_review, reviewer: grouping, result: record }
        end
        failed 'when the user is not a reviewer for the result' do
          before { create :peer_review }
        end
      end
      failed 'when the assignment does not have a peer review' do
        let(:assignment) { create :assignment }
      end
    end
  end

  describe_rule :manage? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    failed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end
end
