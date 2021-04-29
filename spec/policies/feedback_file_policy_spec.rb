describe FeedbackFilePolicy do
  let(:context) { { user: user } }
  let(:record) { create :feedback_file_with_test_run }
  describe_rule :get? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    context 'user is a ta' do
      succeed 'user is a ta' do
        let(:user) { create :ta }
      end
    end
    context 'user is a student' do
      succeed 'who owns the test run' do
        let(:user) { record.test_run.user }
      end
      failed 'who does not own the test run' do
        let(:user) { create(:student) }
      end
    end
  end
end
