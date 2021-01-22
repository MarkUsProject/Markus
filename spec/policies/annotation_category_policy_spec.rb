describe AnnotationCategoryPolicy do
  let(:context) { { user: user } }
  describe_rule :manage? do
    succeed 'when the user is an admin' do
      let(:user) { build(:admin) }
    end
    failed 'when the user is a ta' do
      let(:user) { create(:ta) }
      succeed 'that can manage annotations' do
        let(:user) { create(:ta, manage_assessments: true) }
      end
    end
    failed 'when the user is a student' do
      let(:user) { create(:student) }
    end
  end
  describe_rule :read? do
    succeed 'when the user is an admin' do
      let(:user) { build(:admin) }
    end
    succeed 'when the user is a ta' do
      let(:user) { build(:ta) }
    end
    failed 'when the user is a student' do
      let(:user) { build(:student) }
    end
  end
end
