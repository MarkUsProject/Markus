describe ApplicationPolicy do
  let(:context) { { role: role, real_user: role.human } }
  let(:role) { create :admin }
  let(:policy) { ApplicationPolicy.new(**context) }

  describe_rule :manage? do
    failed
  end

  describe_rule :view_admin_subtabs? do
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

  describe_rule :view_ta_subtabs? do
    failed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :view_student_subtabs? do
    failed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :view_sub_sub_tabs? do
    succeed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :admin? do
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

  describe_rule :ta? do
    failed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :student? do
    failed 'role is an admin' do
      let(:role) { create(:admin) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:role) { create(:student) }
    end
  end
end
