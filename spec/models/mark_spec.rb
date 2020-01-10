describe Mark do
  it { is_expected.to validate_presence_of(:markable_type) }

  it { is_expected.to belong_to(:markable) }
  it { is_expected.to belong_to(:result) }

  it { is_expected.to allow_value('RubricCriterion').for(:markable_type) }
  it { is_expected.to allow_value('FlexibleCriterion').for(:markable_type) }
  it { is_expected.to_not allow_value('').for(:markable_type) }
  it { is_expected.to_not allow_value(nil).for(:markable_type) }

  describe 'when markable type is rubric and the max mark is exceeded' do
    let(:rubric_mark) do
      FactoryBot.build(:rubric_mark, mark: 10)
    end
    it 'should not be valid' do
      expect(rubric_mark).to_not be_valid
    end
  end

  describe 'when markable type is flexible and the max mark is exceeded' do
    let(:flexible_mark) do
      FactoryBot.build(:flexible_mark, mark: 10)
    end
    it 'should not be valid' do
      expect(flexible_mark).to_not be_valid
    end
  end

  describe 'when markable type is flexible and the max mark is exceeded' do
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
      markable = RubricCriterion.find(rubric_mark.markable_id)
      expect(rubric_mark.mark).to eq(4 * markable.weight)
    end
  end

  describe '#scale_mark' do
    let(:rubric_criterion) { create :rubric_criterion }
    let(:flex_criterion) { create :flexible_criterion }
    let(:check_criterion) { create :checkbox_criterion }
    let(:curr_max_mark) { 10 }
    describe 'when the mark is nil' do
      it 'should return nil' do
        [rubric_criterion, flex_criterion, check_criterion].each do |markable|
          mark = create(:mark, markable: markable, mark: nil)
          expect(mark.scale_mark(curr_max_mark, mark.markable.max_mark)).to eq(nil)
        end
      end
    end
    describe 'when prev_max_mark or mark is 0' do
      describe 'when mark is 0' do
        let(:mark) { build(:mark, mark: 0) }
        it 'should return 0' do
          expect(mark.scale_mark(curr_max_mark, 10)).to eq(0)
        end
      end
      describe 'when prev_max_mark is 0' do
        let(:mark) { build(:mark, mark: 10) }
        it 'should return 0' do
          expect(mark.scale_mark(curr_max_mark, 0)).to eq(0)
        end
      end
    end
    describe 'when the mark is not 0 and nil' do
      describe 'when the markable is RubricCriterion and the mark is not 0 and nil' do
        let(:rubric_mark) { create(:rubric_mark, mark: 3) }
        it 'should update and return the new mark' do
          x = rubric_mark.scale_mark(curr_max_mark, rubric_mark.markable.max_mark)
          expect(x).to eq(rubric_mark.mark)
        end
      end
      describe 'when the markable is FlexibleCriterion and the mark is not 0 and nil' do
        let(:flexible_mark) { create(:flexible_mark, mark: 1) }
        it 'should update and return the new mark' do
          y = flexible_mark.scale_mark(curr_max_mark, flexible_mark.markable.max_mark)
          expect(y).to eq(flexible_mark.mark)
        end
      end
      describe 'when the markable is CheckboxCriterion and the mark is not 0 and nil' do
        let(:checkbox_mark) { create(:checkbox_mark, mark: 1) }
        it 'should update and return curr_max_mark' do
          z = checkbox_mark.scale_mark(curr_max_mark, checkbox_mark.markable.max_mark)
          expect(z).to eq(curr_max_mark)
        end
      end
    end
  end
  # private methods
  describe '#ensure_not_released_to_students'
  describe '#update_grouping_mark'
end
