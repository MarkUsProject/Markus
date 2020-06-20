describe Mark do
  it { is_expected.to belong_to(:criterion) }
  it { is_expected.to belong_to(:result) }

  describe 'when mark belongs to rubric criterion and the max mark is exceeded' do
    let(:rubric_mark) do
      FactoryBot.build(:rubric_mark, mark: 10)
    end
    it 'should not be valid' do
      expect(rubric_mark).to_not be_valid
    end
  end

  describe 'when mark belongs to flexible criterion and the max mark is exceeded' do
    let(:flexible_mark) do
      FactoryBot.build(:flexible_mark, mark: 10)
    end
    it 'should not be valid' do
      expect(flexible_mark).to_not be_valid
    end
  end

  describe 'when mark belongs to flexible criterion and the max mark is exceeded' do
    let(:checkbox_mark) do
      FactoryBot.build(:checkbox_mark, mark: 10)
    end
    it 'should not be valid' do
      expect(checkbox_mark).to_not be_valid
    end
  end

  describe 'when mark is less than 0' do
    let(:rubric_mark) do
      FactoryBot.build(:rubric_mark, mark: -1)
    end
    it 'should not be valid' do
      expect(rubric_mark).to_not be_valid
    end
  end

  describe 'mark (column in marks table)' do
    let(:rubric_mark) do
      FactoryBot.create(:rubric_mark, mark: 4)
    end
    it 'equals to mark times weight' do
      related_rubric = rubric_mark.criterion
      expect(rubric_mark.mark).to eq(related_rubric.weight)
    end
  end

  describe '#scale_mark' do
    let(:curr_max_mark) { 10 }
    describe 'when mark is a rubric mark' do
      let(:mark) { create(:rubric_mark, mark: 3) }
      it_behaves_like 'Scale_mark'
    end
    describe 'when mark is a flexible mark' do
      let(:mark) { create(:flexible_mark, mark: 1) }
      it_behaves_like 'Scale_mark'
    end
    describe 'when mark is a checkbox mark' do
      let(:mark) { create(:checkbox_mark, mark: 1) }
      it_behaves_like 'Scale_mark'
    end
  end
  # private methods
  describe '#ensure_not_released_to_students'
  describe '#update_grouping_mark'
end
