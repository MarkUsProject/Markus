describe PeerReviewPolicy do
  let(:context) { { role: role, real_user: role.user } }

  describe_rule :view? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :manage? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :manage_reviewers? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      succeed 'that can manage assessments' do
        let(:role) { create(:ta, manage_assessments: true) }
      end
      failed 'that cannot manage assessments' do
        let(:role) { create(:ta, manage_assessments: false) }
      end
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end
end
