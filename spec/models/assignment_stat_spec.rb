describe AssignmentStat do
  it { is_expected.to belong_to :assignment }

  let(:assignment_stat) { create :assignment_stat }

  describe '#refresh_grade_distribution' do
    it 'updates grade distribution' do
      distribution = Array.new(20) { rand(1...9) }
      dist_str = distribution.to_csv
      allow(assignment_stat.assignment).to receive(:grade_distribution_array).and_return distribution
      assignment_stat.refresh_grade_distribution
      expect(assignment_stat.reload.grade_distribution_percentage).to eq dist_str
    end
  end

  describe '#grade_distribution_array' do
    context 'the grade distribution exists' do
      it 'gets grade the grade distribution' do
        expect(assignment_stat.grade_distribution_array).to eq(Array.new(20) { 1 })
      end
    end
    context 'the grade distribution is nil' do
      let(:assignment_stat) { create :assignment_stat, grade_distribution_percentage: nil }
      it 'gets grade the grade distribution' do
        expect(assignment_stat.grade_distribution_array).to eq(Array.new(20) { 0 })
      end
    end
  end
end
