describe FeedbackFilePolicy do
  let(:context) { { role: role, real_user: role.user } }
  let(:grouping) { create :grouping_with_inviter }
  let(:test_run) { create :test_run, grouping: grouping, role: grouping.inviter }
  let(:test_group_result) { create :test_group_result, test_run: test_run }
  let(:record) { create :feedback_file_with_test_run, test_group_result: test_group_result }

  describe_rule :show? do
    succeed 'role is an instructor' do
      let(:role) { create :instructor }
    end

    context 'role is a ta' do
      let(:ta_membership) { create :ta_membership, grouping: record.grouping }

      succeed 'when the role is assigned the grouping' do
        let(:role) { ta_membership.role }
      end

      failed 'when the role is not assigned the grouping' do
        let(:role) { create :ta }
      end
    end

    context 'role is a student' do
      succeed 'who owns the test run' do
        let(:role) { record.test_group_result.test_run.role }
      end

      failed 'who does not own the test run' do
        let(:role) { create :student }
      end

      context 'when the feedback file is associated with a submission' do
        let(:role) { create :student }
        let(:grouping) { create :grouping_with_inviter, inviter: role }
        let(:submission) { create :version_used_submission, grouping: grouping }
        let(:record) { create :feedback_file, submission: submission }

        succeed 'and result is released' do
          before { submission.current_result.update(released_to_students: true) }
        end

        failed 'and result is not released'

        failed 'and user is not a member of the grouping' do
          let(:role) { create :student }
        end
      end
    end
  end
end
