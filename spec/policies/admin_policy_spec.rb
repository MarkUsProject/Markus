describe AdminPolicy do
  let(:user) { build(:admin) }
  let(:context) { { user: user } }

  describe_rule :run_tests? do
    succeed 'with no additional context'
    context 'authorized with an assignment' do
      let(:context) { { user: user, assignment: assignment } }
      failed 'without tests enabled' do
        let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: false } }
      end
      context 'with tests enabled' do
        let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: true } }
        succeed 'with test groups' do
          let!(:test_group) { create :test_group, assignment: assignment }
        end
        failed 'without test groups'
      end
    end
    context 'authorized with a submission' do
      let(:context) { { user: user, submission: result.submission } }
      failed 'with a released result' do
        let!(:result) { create :released_result }
      end
      succeed 'with a non-release result' do
        let!(:result) { create :complete_result }
      end
    end
  end

  describe_rule :manage_submissions? do
    succeed
  end

  describe_rule :manage_assessments? do
    succeed
  end
end
