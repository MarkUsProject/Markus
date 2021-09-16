describe AutomatedTestsHelper do
  include ApplicationHelper
  describe '.update_test_groups_from_specs' do
    let(:assignment) { create :assignment }
    let(:test_group) { build :test_group, assignment: assignment }
    let(:criterion) { build :flexible_criterion, assignment: assignment }
    let(:criterion_key) { "#{criterion.type}:#{criterion.name}" }
    let(:specs) do
      { 'testers' =>  [
          {
              'test_data' => [{
                                  'extra_info' => {
                                      'test_group_id' => test_group.id,
                                      'criterion' => criterion_key
                                  }
                              }]
          }]
      }
    end
    subject { update_test_groups_from_specs assignment, specs }
    before { allow(AutomatedTestsHelper).to receive(:flash_message) }
    context 'when the test group exists' do
      before { test_group.save }
      it 'should not create a new test group' do
        expect { subject }.not_to change { TestGroup.count }
      end
      it 'should use the test group id' do
        subject
        expect(specs['testers'][0]['test_data'][0]['extra_info']['test_group_id']).to eq test_group.id
      end
    end
    context 'when the test group does not exist' do
      it 'should create a new test group' do
        expect { subject }.to change { TestGroup.count }.from(0).to(1)
      end
      it 'should use the newly created test group' do
        subject
        expect(specs['testers'][0]['test_data'][0]['extra_info']['test_group_id']).to eq TestGroup.first.id
      end
    end
    context 'when the criterion exists' do
      before { criterion.save }
      it 'should use the criterion' do
        subject
        expect(TestGroup.first.criterion).to eq criterion
      end
    end
    context 'when the criterion does not exist' do
      before { subject }
      it 'should not set the criterion on the test group' do
        expect(TestGroup.first.criterion).to be_nil
      end
    end
  end
end
