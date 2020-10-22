describe ApplicationPolicy do
  let(:context) { { user: user } }
  let(:user) { create :admin }
  let(:policy) { ApplicationPolicy.new(**context) }
  describe :index? do
    it 'should call manage' do
      expect(policy).to receive(:manage?)
      policy.apply(:index?)
    end
  end

  describe :create? do
    it 'should call manage' do
      expect(policy).to receive(:manage?)
      policy.apply(:create?)
    end
  end

  describe_rule :manage? do
    failed
  end

  describe_rule :view_admin_subtabs? do
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

  describe_rule :view_ta_subtabs? do
    failed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    succeed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :view_student_subtabs? do
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

  describe_rule :view_sub_sub_tabs? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    succeed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :admin? do
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

  describe_rule :ta? do
    failed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    succeed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :student? do
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
