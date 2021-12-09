describe PeerReviewPolicy do
  let(:context) { { role: role, real_user: role.end_user } }

  describe_rule :view? do
    succeed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :manage? do
    succeed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :manage_reviewers? do
    succeed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    context 'role is a ta' do
      succeed 'that can manage assessments' do
        let(:role) { create :ta, manage_assessments: true }
      end
      failed 'that cannot manage assessments' do
        let(:role) { create :ta, manage_assessments: false }
      end
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end
end
