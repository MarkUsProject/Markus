describe FeedbackFilePolicy do
  let(:context) { { user: user } }
  let(:record) { create :feedback_file_with_test_run }

  describe_rule :manage? do
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
    end
  end
end
