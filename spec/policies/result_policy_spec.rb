describe ResultPolicy do
  let(:context) { { role: role, real_user: role.user } }

  describe_rule :view? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      let(:record) { create :complete_result, submission: create(:submission, grouping: grouping) }
      let(:grouping) { create :grouping_with_inviter, inviter: create(:student), assignment: assignment }
      let(:assignment) { create :assignment_with_peer_review }
      succeed 'when they are assigned to grade the given group\'s submission' do
        let!(:role) { create(:ta) }
        let!(:ta_membership) { create :ta_membership, role: role, grouping: grouping }
      end
      succeed 'when they can manage submissions' do
        let!(:role) { create(:ta, manage_submissions: true) }
      end
      failed 'when they aren\'t assigned to grade the given group\'s submission' do
        let(:role) { create(:ta) }
      end
    end
    failed 'role is a student who is not part of the grouping' do
      let(:role) { create :student }
      let(:record) { create :complete_result }
    end
    describe 'role is a student who is part of the grouping' do
      let(:role) { create :student }
      let(:grouping) { create :grouping_with_inviter_and_submission, inviter: role }
      let(:record) { grouping.current_result }
      let(:assignment) { record.grouping.assignment }
      succeed 'assignment.release_with_urls is false' do
        before { assignment.update! release_with_urls: false }
      end
      context 'assignment.release_with_urls is true' do
        before { assignment.update! release_with_urls: true }
        let(:context) { { role: role, real_user: role.user, view_token: view_token } }
        failed 'the view token does not match the record token' do
          let(:view_token) { "#{record.view_token}abc123" }
        end
        context 'the view token matches the record token' do
          let(:view_token) { record.view_token }
          succeed 'the token does not have an expiry set'
          succeed 'the record has a token expiry set in the future' do
            before { record.update! view_token_expiry: 1.hour.from_now }
          end
          failed 'the record has a token expiry set in the past' do
            before { record.update! view_token_expiry: 1.hour.ago }
          end
        end
      end
    end
    succeed 'role is a student who is a reviewer' do
      let(:role) { create(:student) }
      let(:record) { create :complete_result, submission: create(:submission, grouping: grouping) }
      let(:grouping) { create :grouping_with_inviter, inviter: role, assignment: assignment }
      let(:assignment) { create :assignment_with_peer_review }
      let(:record) { create :complete_result, submission: create(:submission, grouping: review_grouping) }
      let(:grouping) { create :grouping_with_inviter, inviter: role, assignment: assignment.pr_assignment }
      let(:review_grouping) { create :grouping_with_inviter, assignment: assignment }
      before { create :peer_review, reviewer: grouping, result: record }
    end
  end

  describe_rule :view_marks? do
    let(:record) { create :complete_result }
    failed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student who is not part of the grouping' do
      let(:role) { create :student }
    end
    describe 'role is a student who is part of the grouping' do
      let(:role) { create :student }
      let(:grouping) { create :grouping_with_inviter_and_submission, inviter: role }
      let(:record) { grouping.current_result }
      let(:assignment) { record.grouping.assignment }
      succeed 'assignment.release_with_urls is false' do
        before { assignment.update! release_with_urls: false }
      end
      context 'assignment.release_with_urls is true' do
        before { assignment.update! release_with_urls: true }
        let(:context) { { role: role, real_user: role.user, view_token: view_token } }
        failed 'the view token does not match the record token' do
          let(:view_token) { "#{record.view_token}abc123" }
        end
        context 'the view token matches the record token' do
          let(:view_token) { record.view_token }
          succeed 'the token does not have an expiry set'
          succeed 'the record has a token expiry set in the future' do
            before { record.update! view_token_expiry: 1.hour.from_now }
          end
          failed 'the record has a token expiry set in the past' do
            before { record.update! view_token_expiry: 1.hour.ago }
          end
        end
      end
    end
  end

  describe_rule :run_tests? do
    let(:record) { create :complete_result, submission: submission }
    let(:submission) { create :submission, grouping: grouping }
    let(:grouping) { create :grouping, assignment: assignment }
    let(:assignment) { create :assignment }
    context 'role is an instructor' do
      let(:role) { create :instructor }
      failed 'when result is released' do
        let(:record) { create :released_result }
      end
      context 'when result is not released' do
        failed 'without tests enabled' do
          let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: false } }
        end
        context 'with test enabled' do
          let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: true } }
          succeed 'when remote_autotest_settings exist' do
            before { assignment.update! remote_autotest_settings_id: 1 }
          end
          failed 'without test groups'
        end
      end
    end
    context 'role is a ta' do
      failed 'without run test permissions' do
        let(:role) { create :ta, run_tests: false }
      end
      context 'with run test permissions' do
        let(:role) { create :ta, run_tests: true }
        failed 'when result is released' do
          let(:record) { create :released_result }
        end
        context 'when result is not released' do
          failed 'without tests enabled' do
            let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: false } }
          end
          context 'with test enabled' do
            let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: true } }
            succeed 'when remote_autotest_settings exist' do
              before { assignment.update! remote_autotest_settings_id: 1 }
            end
            failed 'without test groups'
          end
        end
      end
    end
    context 'role is a student' do
      let(:role) { create :student }
      let(:assignment) { create :assignment, assignment_properties_attributes: assignment_attrs }
      let(:assignment_attrs) { {} }
      context 'when the role is a member of the grouping' do
        let(:grouping) { create :grouping_with_inviter, assignment: assignment, inviter: role, test_tokens: 1 }
        failed 'when there is a test in progress' do
          before { allow(grouping).to receive(:student_test_run_in_progress?).and_return true }
        end
        failed 'when there are no tokens available' do
          let(:grouping) { create :grouping_with_inviter, inviter: role, test_tokens: 0 }
        end
        failed 'when the due date has passed' do
          let(:assignment) { create :assignment, due_date: 1.day.ago }
          let(:grouping) { create :grouping_with_inviter, assignment: assignment, inviter: role, test_tokens: 1 }
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
      failed 'when the role is not a member of the grouping' do
        let(:grouping) { create :grouping_with_inviter, test_tokens: 1 }
      end
    end
  end

  describe_rule :grade? do
    let(:record) { create :complete_result, submission: create(:submission, grouping: grouping) }
    let(:grouping) { create :grouping_with_inviter, inviter: create(:student), assignment: assignment }
    let(:assignment) { create :assignment_with_peer_review }
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      succeed 'when they are assigned to grade the given group\'s submission' do
        let!(:role) { create(:ta) }
        let!(:ta_membership) { create :ta_membership, role: role, grouping: grouping }
      end
      succeed 'when they can manage submissions' do
        let!(:role) { create(:ta, manage_submissions: true) }
      end
      failed 'when they aren\'t assigned to grade the given group\'s submission' do
        let(:role) { create(:ta) }
      end
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :review? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      let(:record) { create :complete_result, submission: create(:submission, grouping: grouping) }
      let(:grouping) { create :grouping_with_inviter, inviter: create(:student), assignment: assignment, tas: [role] }
      let(:assignment) { create :assignment_with_peer_review }
      succeed 'when they can manage submissions' do
        let!(:role) { create(:ta, manage_submissions: true) }
      end
      succeed 'when they are assigned to grade the given group\'s submission' do
        let(:role) { create(:ta) }
      end
      failed 'when they have not been assigned to grade the given group\'s submission' do
        # Assure the grouping used does not have any ta's assigned to grade their submission
        let(:grouping) { create :grouping_with_inviter, inviter: create(:student), assignment: assignment }
        let(:role) { create(:ta) }
      end
    end

    context 'role is a student' do
      let(:role) { create(:student) }
      let(:record) { create :complete_result, submission: create(:submission, grouping: grouping) }
      let(:grouping) { create :grouping_with_inviter, inviter: role, assignment: assignment }
      context 'when the assignment has a peer review' do
        let(:assignment) { create :assignment_with_peer_review }
        succeed 'when the role is a reviewer for the result' do
          let(:record) { create :complete_result, submission: create(:submission, grouping: review_grouping) }
          let(:grouping) { create :grouping_with_inviter, inviter: role, assignment: assignment.pr_assignment }
          let(:review_grouping) { create :grouping_with_inviter, assignment: assignment }
          before { create :peer_review, reviewer: grouping, result: record }
        end
        failed 'when the role is not a reviewer for the result' do
          before { create :peer_review }
        end
      end
      failed 'when the assignment does not have a peer review' do
        let(:assignment) { create :assignment }
      end
    end
  end

  describe_rule :update_mark? do
    let(:record) { create :complete_result, submission: create(:submission, grouping: grouping) }
    let(:grouping) { create :grouping_with_inviter, inviter: create(:student), assignment: assignment }
    let(:assignment) { create :assignment_with_peer_review }
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      let(:grouping) do
        create :grouping_with_inviter, inviter: create(:student),
                                       assignment: assignment, tas: [role]
      end
      succeed 'when they can manage submissions' do
        let!(:role) { create(:ta, manage_submissions: true) }
      end
      context 'when they are assigned to grade the given group\'s submission' do
        let!(:role) { create(:ta) }
        succeed 'when the assign_graders_to_criteria attribute for the associated assignment is false'
        context 'when the assign_graders_to_criteria attribute for the associated assignment is true' do
          let(:context) { { role: role, real_user: role.user, criterion_id: criterion_id } }
          let(:assignment) do
            assignment = create :assignment_with_peer_review
            assignment.assignment_properties.update(assign_graders_to_criteria: true)
            assignment
          end
          let(:criterion) { create :rubric_criterion, assignment: assignment }
          succeed 'when the ta is assigned to grade the given criteria' do
            let(:criterion_id) { (create :criterion_ta_association, ta: role, criterion: criterion).criterion_id }
          end
          failed 'when the ta is not assigned to grade the given criteria' do
            let(:criterion_id) { criterion.id }
          end
        end
      end
      failed 'when they have not been assigned to grade the given group\'s submission' do
        # Assure the grouping used does not have any ta's assigned to grade their submission
        let(:grouping) { create :grouping_with_inviter, inviter: create(:student), assignment: assignment }
        let(:role) { create(:ta) }
      end
    end

    context 'role is a student' do
      let(:role) { create(:student) }
      let(:record) { create :complete_result, submission: create(:submission, grouping: grouping) }
      let(:grouping) { create :grouping_with_inviter, inviter: role, assignment: assignment }
      context 'when the assignment has a peer review' do
        let(:assignment) { create :assignment_with_peer_review }
        succeed 'when the role is a reviewer for the result' do
          let(:record) { create :complete_result, submission: create(:submission, grouping: review_grouping) }
          let(:grouping) { create :grouping_with_inviter, inviter: role, assignment: assignment.pr_assignment }
          let(:review_grouping) { create :grouping_with_inviter, assignment: assignment }
          before { create :peer_review, reviewer: grouping, result: record }
        end
        failed 'when the role is not a reviewer for the result' do
          before { create :peer_review }
        end
      end
      failed 'when the assignment does not have a peer review' do
        let(:assignment) { create :assignment }
      end
    end
  end

  describe_rule :set_released_to_students? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      let(:record) { create :complete_result, submission: create(:submission, grouping: grouping) }
      let(:grouping) { create :grouping_with_inviter, inviter: create(:student), assignment: assignment, tas: [role] }
      let(:assignment) { create :assignment_with_peer_review }
      succeed 'that can manage submissions' do
        let(:role) { create :ta, manage_submissions: true }
      end
      failed 'that cannot manage submissions' do
        let(:role) { create :ta, manage_submissions: false }
      end
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :manage? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :view_token_check? do
    let(:record) { create :complete_result }
    failed 'role is an instructor' do
      let(:role) { create :instructor }
    end
    failed 'role is a ta' do
      let(:role) { create :ta }
    end
    failed 'role is a student who is not part of the grouping' do
      let(:role) { create :student }
    end
    describe 'role is a student who is part of the grouping' do
      let(:role) { create :student }
      let(:grouping) { create :grouping_with_inviter_and_submission, inviter: role }
      let(:record) { grouping.current_result }
      let(:assignment) { record.grouping.assignment }
      failed 'assignment.release_with_urls is false' do
        before { assignment.update! release_with_urls: false }
      end
      context 'assignment.release_with_urls is true' do
        before { assignment.update! release_with_urls: true }
        failed 'view_token is expired' do
          before { record.update! view_token_expiry: 1.minute.ago }
        end
        succeed 'view_token is not expired' do
          before { record.update! view_token_expiry: 1.minute.from_now }
        end
      end
    end
  end
end
