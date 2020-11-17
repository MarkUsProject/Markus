describe PeerReviewPolicy do
  let(:context) { { user: user } }

  describe_rule :view? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    succeed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    succeed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :manage? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    failed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :manage_reviewers? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    context 'user is a ta' do
      succeed 'that can manage assessments' do
        let(:user) { create :ta, manage_assessments: true }
      end
      failed 'that cannot manage assessments' do
        let(:user) { create :ta, manage_assessments: false }
      end
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end
end
