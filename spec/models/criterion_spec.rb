describe Criterion do
  let(:assignment) { create(:assignment_with_criteria_and_results) }

  describe '#export_name' do
    it 'returns the criterion name for non-bonus criteria' do
      criterion = create(:flexible_criterion, name: 'Correctness', assignment: assignment)

      expect(criterion.export_name).to eq 'Correctness'
    end

    it 'identifies bonus criteria' do
      criterion = create(:flexible_criterion, name: 'Style', assignment: assignment, bonus: true)

      expect(criterion.export_name).to eq "Style (#{Criterion.human_attribute_name(:bonus)})"
    end
  end

  describe 'reset marking states' do
    before('resets marking states with at least one result') do
      assignment.current_results do |result|
        result.update(marking_state: Result::MARKING_STATES[:complete])
      end
      Criterion.reset_marking_states(assignment.id)
    end

    it 'resets marking states with at least one result' do
      expect(assignment.current_results.all? { |result| result.marking_state == Result::MARKING_STATES[:incomplete] })
        .to be(true)
    end
  end
end
