describe SubmissionPolicy do
  let(:real_user) { role.user }
  let(:context) { { role: role, real_user: real_user } }

  describe_rule :manage? do
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
        let(:role) { create :ta, run_tests: true }
      end
      failed 'that cannot run tests' do
        let(:role) { create :ta, run_tests: false }
      end
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :manage_subdirectories? do
    [:student, :ta, :instructor].each do |role_type|
      succeed "as a #{role_type}" do
        let(:role) { create role_type }
      end
    end
  end

  describe_rule :notebook_content? do
    [:student, :ta, :instructor].each do |role_type|
      context "as a #{role_type}" do
        let(:role) { create role_type }
        succeed 'scanner dependencies are installed' do
          before { allow(Rails.application.config).to receive(:nbconvert_enabled).and_return(true) }
        end
        failed 'scanner dependencies are not installed' do
          before { allow(Rails.application.config).to receive(:nbconvert_enabled).and_return(false) }
        end
      end
    end
  end

  describe_rule :download_file? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      let(:complete_result) { create :complete_result, submission: create(:submission, grouping: grouping) }
      let(:record) { complete_result.submission }
      let(:grouping) { create :grouping_with_inviter, inviter: create(:student), assignment: assignment }
      let(:assignment) { create :assignment_with_peer_review }
      succeed 'when they can manage submissions' do
        let!(:role) { create(:ta, manage_submissions: true) }
      end
      succeed 'when they are assigned to grade the given group\'s submission' do
        let!(:role) { create(:ta) }
        let!(:ta_membership) { create :ta_membership, role: role, grouping: grouping }
      end
      failed 'when they aren\'t assigned to grade the given group\'s submission' do
        let(:role) { create(:ta) }
      end
    end
    context 'role is a student' do
      let(:assignment) { create :assignment_with_peer_review_and_groupings_results }
      let(:current_result) { assignment.groupings.first.current_result }
      let(:record) { current_result.submission }
      context 'role is a reviewer for the current result' do
        let(:reviewer_grouping) { assignment.pr_assignment.groupings.first }
        let(:role) { reviewer_grouping.accepted_students.first }
        before { create :peer_review, reviewer: reviewer_grouping, result: current_result }
        succeed 'from_codeviewer is true' do
          let(:context) { { role: role, real_user: role.user, from_codeviewer: true } }
        end
        failed 'from_codeviewer is false' do
          let(:context) { { role: role, real_user: role.user, from_codeviewer: false } }
        end
      end
      context 'role is not a reviewer for the current result' do
        context 'role is an accepted member of the results grouping' do
          let(:role) { current_result.grouping.accepted_students.first }
          succeed 'and there is no file selected'
          succeed 'and the selected file is associated with the current submission' do
            let(:select_file) { create(:submission_file, submission: record) }
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
end
