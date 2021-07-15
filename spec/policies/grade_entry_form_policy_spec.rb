describe GradeEntryFormPolicy do
  let(:context) { { user: user } }
  describe_rule :manage? do
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
  describe_rule :grade? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    succeed 'that can manage assessments' do
      let(:user) { create :ta }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end
  describe_rule :student_interface? do
    failed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    failed 'that can manage assessments' do
      let(:user) { create :ta }
    end
    succeed 'user is a student' do
      let(:user) { create(:student) }
    end
  end
  describe_rule :switch? do
    succeed
  end
end
