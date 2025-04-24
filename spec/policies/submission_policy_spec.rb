describe SubmissionPolicy do
  let(:real_user) { role.user }
  let(:context) { { role: role, real_user: real_user } }

  describe_rule :manage? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      succeed 'that can manage submissions' do
        let(:role) { create(:ta, manage_submissions: true) }
      end
      failed 'that cannot manage submissions' do
        let(:role) { create(:ta, manage_submissions: false) }
      end
    end

    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :file_manager? do
    failed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :run_tests? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      succeed 'that can run tests' do
        let(:role) { create(:ta, run_tests: true) }
      end
      failed 'that cannot run tests' do
        let(:role) { create(:ta, run_tests: false) }
      end
    end

    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :manage_subdirectories? do
    [:student, :ta, :instructor].each do |role_type|
      succeed "as a #{role_type}" do
        let(:role) { create(role_type) }
      end
    end
  end

  describe_rule :download_file? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      let(:complete_result) { create(:complete_result, submission: create(:submission, grouping: grouping)) }
      let(:record) { complete_result.submission }
      let(:grouping) { create(:grouping_with_inviter, inviter: create(:student), assignment: assignment) }
      let(:assignment) { create(:assignment_with_peer_review) }
      let!(:role) { create(:ta) }

      succeed 'when they can manage submissions' do
        let!(:role) { create(:ta, manage_submissions: true) }
      end
      succeed 'when they are assigned to grade the given group\'s submission' do
        before { create(:ta_membership, role: role, grouping: grouping) }
      end
      failed 'when they aren\'t assigned to grade the given group\'s submission'
    end

    context 'role is a student' do
      let(:assignment) { create(:assignment_with_peer_review_and_groupings_results) }
      let(:current_result) { assignment.groupings.first.current_result }
      let(:record) { current_result.submission }

      context 'role is a reviewer for the current result' do
        let(:reviewer_grouping) { assignment.pr_assignment.groupings.first }
        let(:role) { reviewer_grouping.accepted_students.first }

        before { create(:peer_review, reviewer: reviewer_grouping, result: current_result) }

        succeed 'from_codeviewer is true' do
          let(:context) { { role: role, real_user: role.user, from_codeviewer: true } }
        end
        failed 'from_codeviewer is false' do
          let(:context) { { role: role, real_user: role.user, from_codeviewer: false } }
        end
      end

      context 'role is not a reviewer for the current result' do
        succeed 'role is an accepted member of the results grouping' do
          let(:role) { current_result.grouping.accepted_students.first }
        end
        failed 'role is not an accepted member of the results grouping' do
          let(:role) { create(:student) }
        end
      end
    end
  end
  describe_rule :change_remark_status? do
    let(:record) { create(:complete_result) }
    failed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student who is not part of the grouping' do
      let(:role) { create(:student) }
    end
    describe 'role is a student who is part of the grouping' do
      let(:role) { create(:student) }
      let(:grouping) { create(:grouping_with_inviter_and_submission, inviter: role) }
      let(:result) { grouping.current_result }
      let(:record) { result.submission }
      let(:assignment) { record.grouping.assignment }

      succeed 'assignment.release_with_urls is false' do
        before { assignment.update! release_with_urls: false }
      end
      context 'assignment.release_with_urls is true' do
        before { assignment.update! release_with_urls: true }

        let(:context) { { role: role, real_user: role.user, view_token: view_token } }

        failed 'the view token does not match the record token' do
          let(:view_token) { "#{result.view_token}abc123" }
        end
        context 'the view token matches the record token' do
          let(:view_token) { result.view_token }

          succeed 'the token does not have an expiry set'
          succeed 'the record has a token expiry set in the future' do
            before { result.update! view_token_expiry: 1.hour.from_now }
          end
          failed 'the record has a token expiry set in the past' do
            before { result.update! view_token_expiry: 1.hour.ago }
          end
        end
      end
    end
  end
end
