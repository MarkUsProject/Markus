describe ApplicationPolicy do
  let(:context) { { role: role, real_user: role.user } }
  let(:role) { create :instructor }
  let(:policy) { ApplicationPolicy.new(**context) }

  describe_rule :manage? do
    failed
  end

  describe_rule :view_instructor_subtabs? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
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
    failed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :view_student_subtabs? do
    failed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :view_sub_sub_tabs? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :instructor? do
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

  describe_rule :ta? do
    failed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :student? do
    failed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    succeed 'role is a student' do
      let(:role) { create(:student) }
    end
  end
end
