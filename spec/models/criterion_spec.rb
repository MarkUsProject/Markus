describe Criterion do
  let(:assignment) { create(:assignment_with_criteria_and_results) }

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
