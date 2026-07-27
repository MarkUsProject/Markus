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
              'criterion' => nil
            }
          }]
        }
      ] }
    end

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

      before { criterion.save }

      it 'should use the criterion' do
        subject
        expect(assignment.test_groups.first.criterion).to eq criterion
      end
    end

    context 'when the criterion does not exist' do
      let!(:test_group_id) { create(:test_group, assignment: assignment).id }
      let(:specs_with_bad_criterion) do
        { 'testers' => [
          {
            'test_data' => [{
              'extra_info' => {
                'test_group_id' => test_group_id,
                'criterion' => 'nonexistent_criterion'
              }
            }]
          }
        ] }
      end

      it 'raises with the invalid criterion name' do
        expect { update_test_groups_from_specs(assignment, specs_with_bad_criterion) }
          .to raise_error(/Unable to find a criterion with name/)
      end

      it 'does not persist any changes' do
        begin
          update_test_groups_from_specs(assignment, specs_with_bad_criterion)
        rescue StandardError
          nil
        end
        expect(assignment.reload.autotest_settings).to be_nil
      end
    end
  end
end
