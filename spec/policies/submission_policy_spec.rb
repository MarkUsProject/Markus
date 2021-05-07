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
end
