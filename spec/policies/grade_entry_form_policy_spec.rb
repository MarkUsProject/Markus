describe GradeEntryFormPolicy do
  let(:context) { { role: role, real_user: role.user } }

  describe_rule :manage? do
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
  describe_rule :grade? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'that can manage assessments' do
      let(:role) { create(:ta) }
    end
    failed 'user is a student' do
      let(:role) { create(:student) }
    end
  end
  describe_rule :student_interface? do
    failed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'that can manage assessments' do
      let(:role) { create(:ta) }
    end
    succeed 'user is a student' do
      let(:role) { create(:student) }
    end
  end
  describe_rule :switch? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'that can manage assessments' do
      let(:role) { create(:ta) }
    end
    succeed 'user is a student' do
      let(:role) { create(:student) }
    end
  end
end
