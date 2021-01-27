describe SubmissionPolicy do
  let(:context) { { user: user } }

  describe_rule :manage? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    context 'user is a ta' do
      succeed 'that can manage submissions' do
        let(:user) { create :ta, manage_submissions: true }
      end
      failed 'that cannot manage submissions' do
        let(:user) { create :ta, manage_submissions: false }
      end
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :file_manager? do
    failed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    failed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    succeed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :get_feedback_file? do
    let(:record) { create :submission }
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    context 'user is a ta' do
      let(:user) { create(:ta) }
      succeed 'ta is assigned to the submission grouping' do
        before { create :ta_membership, user: user, grouping: record.grouping }
      end
      failed 'ta is not to the submission grouping'
    end
    context 'user is a student' do
      let(:user) { create(:student) }
      context 'user is a member of the grouping' do
        let(:grouping) { create :grouping_with_inviter, inviter: user }
        let(:record) { create :version_used_submission, grouping: grouping }
        succeed 'result is released' do
          before { create :released_result, submission: record }
        end
        failed 'result is not released' do
          before { create :complete_result, submission: record }
        end
      end
      failed 'user is not a member of the grouping'
    end
  end
end
