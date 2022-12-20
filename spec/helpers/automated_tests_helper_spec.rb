describe AutomatedTestsHelper do
  include ApplicationHelper
  describe '.update_test_groups_from_specs' do
    let(:assignment) { create :assignment }
    let(:criterion) { build :flexible_criterion, assignment: assignment }
    let(:specs) do
      { 'testers' => [
        {
          'test_data' => [{
            'extra_info' => {
              'name' => test_group&.name,
              'display_output' => test_group&.display_output,
              'criterion' => test_group&.criterion&.name
            }
          }]
        }
      ] }
    end
    subject { update_test_groups_from_specs assignment, specs }
    before { allow(AutomatedTestsHelper).to receive(:flash_message) }
    context 'when the test group exists' do
      let!(:test_group) { create(:test_group, assignment: assignment, tester_index: 0) }
      it 'should not create a new test group' do
        expect { subject }.not_to(change { assignment.test_groups.count })
      end
    end
    context 'when the test group does not exist' do
      let(:test_group) { nil }
      it 'should create a new test group' do
        expect { subject }.to change { assignment.test_groups.count }.from(0).to(1)
      end
    end
    context 'when the criterion exists' do
      let(:test_group) { create(:test_group, assignment: assignment, criterion: criterion) }
      it 'should use the criterion' do
        subject
        expect(assignment.test_groups.first.criterion).to eq criterion
      end
    end
    context 'when the criterion does not exist' do
      let(:test_group) { create(:test_group, assignment: assignment) }
      before { subject }
      it 'should not set the criterion on the test group' do
        expect(assignment.test_groups.first.criterion).to be_nil
      end
    end
  end
end
