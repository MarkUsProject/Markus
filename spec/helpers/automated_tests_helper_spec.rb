describe AutomatedTestsHelper do
  include ApplicationHelper

  describe '.update_test_groups_from_specs' do
    subject { update_test_groups_from_specs assignment, specs }

    let(:assignment) { create(:assignment) }
    let(:criterion) { build(:flexible_criterion, assignment: assignment) }
    let(:specs) do
      { 'testers' => [
        {
          'test_data' => [{
            'extra_info' => {
              'test_group_id' => test_group_id,
              'criterion' => criterion.name
            }
          }]
        }
      ] }
    end

    before { allow(AutomatedTestsHelper).to receive(:flash_message) }

    context 'when the test group exists' do
      let!(:test_group_id) { create(:test_group, assignment: assignment).id }

      it 'should not create a new test group' do
        expect { subject }.not_to(change { assignment.test_groups.count })
      end

      it 'should use the existing test group id' do
        subject
        expect(specs['testers'][0]['test_data'][0]).to eq test_group_id
      end
    end

    context 'when the test group does not exist' do
      let(:test_group_id) { nil }

      it 'should create a new test group' do
        expect { subject }.to change { assignment.test_groups.count }.from(0).to(1)
      end

      it 'should use the newly created test group id' do
        subject
        expect(specs['testers'][0]['test_data'][0]).to eq assignment.test_groups.first.id
      end
    end

    context 'when the criterion exists' do
      let(:test_group_id) { create(:test_group, assignment: assignment).id }

      before { criterion.save }

      it 'should use the criterion' do
        subject
        expect(assignment.test_groups.first.criterion).to eq criterion
      end
    end

    context 'when the criterion does not exist' do
      let(:test_group_id) { create(:test_group, assignment: assignment).id }

      before { subject }

      it 'should not set the criterion on the test group' do
        expect(assignment.test_groups.first.criterion).to be_nil
      end
    end
  end
end
