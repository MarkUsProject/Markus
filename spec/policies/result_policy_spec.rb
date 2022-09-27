describe ResultPolicy do
  let(:context) { { role: role, real_user: role.user } }

  describe_rule :view? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:role) { create(:student) }
      let(:record) { create :complete_result }
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
          succeed 'with test groups' do
            let!(:test_group) { create :test_group, assignment: assignment }
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
            succeed 'with test groups' do
              let!(:test_group) { create :test_group, assignment: assignment }
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
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :review? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
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

  describe_rule :download? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    context 'role is a student' do
      let(:assignment) { create :assignment_with_peer_review_and_groupings_results }
      let(:record) { assignment.groupings.first.current_result }
      context 'role is a reviewer for the current result' do
        let(:reviewer_grouping) { assignment.pr_assignment.groupings.first }
        let(:role) { reviewer_grouping.accepted_students.first }
        before { create :peer_review, reviewer: reviewer_grouping, result: record }
        succeed 'from_codeviewer is true' do
          let(:context) { { role: role, real_user: role.user, from_codeviewer: true } }
        end
        failed 'from_codeviewer is false' do
          let(:context) { { role: role, real_user: role.user, from_codeviewer: false } }
        end
      end
      context 'role is not a reviewer for the current result' do
        context 'role is an accepted member of the results grouping' do
          let(:role) { record.grouping.accepted_students.first }
          succeed 'and there is no file selected'
          succeed 'and the selected file is associated with the current submission' do
            let(:select_file) { create(:submission_file, submission: record.submission) }
            let(:context) { { role: role, real_user: role.user, select_file: select_file } }
          end
          failed 'and the selected file is associated with a different submission' do
            let(:select_file) { create(:submission_file) }
            let(:context) { { role: role, real_user: role.user, select_file: select_file } }
          end
        end
        failed 'role is not an accepted member of the results grouping' do
          let(:role) { create(:student) }
        end
      end
    end
  end

  describe_rule :submit_result_token? do
    failed 'role is an instructor' do
      let(:role) { create :instructor }
    end
    failed 'role is a ta' do
      let(:role) { create :ta }
    end
    describe 'role is a student' do
      let(:role) { create :student }
      let(:record) { create :complete_result }
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
