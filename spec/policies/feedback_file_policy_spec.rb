describe FeedbackFilePolicy do
  let(:context) { { user: user } }
  let(:grouping) { create :grouping_with_inviter }
  let(:test_run) { create :test_run, grouping: grouping, user: grouping.inviter }
  let(:test_group_result) { create :test_group_result, test_run: test_run }
  let(:record) { create :feedback_file_with_test_run, test_group_result: test_group_result }

  describe_rule :show? do
    succeed 'user is an admin' do
      let(:user) { create :admin }
    end

    context 'user is a ta' do
      let(:ta_membership) { create :ta_membership, grouping: record.grouping }

      succeed 'when the user is assigned the grouping' do
        let(:user) { ta_membership.user }
      end

      failed 'when the user is not assigned the grouping' do
        let(:user) { create :ta }
      end
    end

    context 'user is a student' do
      succeed 'who owns the test run' do
        let(:user) { record.test_group_result.test_run.user }
      end

      failed 'who does not own the test run' do
        let(:user) { create :student }
      end

      context 'when the feedback file is associated with a submission' do
        let(:user) { create :student }
        let(:grouping) { create :grouping_with_inviter, inviter: user }
        let(:submission) { create :version_used_submission, grouping: grouping }
        let(:record) { create :feedback_file, submission: submission }

        succeed 'and result is released' do
          before { submission.current_result.update(released_to_students: true) }
        end

        failed 'and result is not released'

        failed 'and user is not a member of the grouping' do
          let(:user) { create :student }
        end
      end
    end
  end
end
