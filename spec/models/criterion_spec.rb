describe Criterion do
  let(:assignment) { create :assignment_with_criteria_and_results }
  context 'when uploading criteria from yaml' do
    before('resets marking states with at least one result') do
      assignment.current_results do |result|
        instance_variable_set(result.marking_state, Result::MARKING_STATES[:complete])
      end
      Criterion.reset_marking_states(assignment.id)
    end
    it 'resets marking states with at least one result' do
      expect(assignment.current_results.all? { |result| result.marking_state == Result::MARKING_STATES[:incomplete] })
        .to eq(true)
    end
  end
end
