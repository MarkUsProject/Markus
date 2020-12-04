describe AnnotationCategoryPolicy do
  describe_rule :manage? do
    let(:context) { { user: user } }
    succeed 'when the user is an admin' do
      let(:user) { build(:admin) }
    end
    failed 'when the user is a ta' do
      let(:user) { create(:ta) }
      succeed 'that can manage annotations' do
        let(:user) { create(:ta, manage_assessments: true) }
      end
    end
  end
end
