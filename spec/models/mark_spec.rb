require 'spec_helper'

describe Mark do

  it { is_expected.to validate_presence_of(:result_id) }
  it { is_expected.to validate_presence_of(:markable_id) }
  it { is_expected.to validate_presence_of(:markable_type) }

  it { should belong_to(:markable) }
  it { should belong_to(:result) }

  it { should allow_value(1).for(:result_id) }
  it { should allow_value(2).for(:result_id) }
  it { should allow_value(3).for(:result_id) }
  it { should_not allow_value(-2).for(:result_id) }
  it { should_not allow_value(-1).for(:result_id) }
  it { should_not allow_value(0).for(:result_id) }

  it { should allow_value(1).for(:markable_id) }
  it { should allow_value(2).for(:markable_id) }
  it { should allow_value(3).for(:markable_id) }
  it { should_not allow_value(-2).for(:markable_id) }
  it { should_not allow_value(-1).for(:markable_id) }
  it { should_not allow_value(0).for(:markable_id) }

  it { should allow_value('RubricCriterion').for(:markable_type) }
  it { should allow_value('FlexibleCriterion').for(:markable_type) }
  it { should_not allow_value('').for(:markable_type) }
  it { should_not allow_value(nil).for(:markable_type) }

  describe '#valid_mark' do

    context 'when markable type is rubric' do
      let(:rubric_mark) do
        create(:rubric_mark, mark: 4, markable_type: 'RubricCriterion')
      end
      it 'is valid to have rubric briterion mark smaller or equals to four' do
        expect(rubric_mark.valid_mark).to be_truthy
      end
    end

    context 'when markable type is flexible' do
      let(:flexible_mark) do
        create(:flexible_mark, mark: 0, markable_type: 'FlexibleCriterion')
      end
      it 'is valid to have rubric briterion mark equals zero' do
        expect(flexible_mark.valid_mark).to be_truthy
      end
    end
  end

  describe '#get_mark' do
    let(:rubric_mark) do
      create(:rubric_mark, mark: 4, markable_type: 'RubricCriterion')
    end
    it 'equals to mark times weight' do
      markable = RubricCriterion.find(rubric_mark.markable_id)
      expect(rubric_mark.get_mark).to eq(rubric_mark.mark * markable.weight)
    end
  end

  # private methods
  describe '#ensure_not_released_to_students'
  describe '#update_grouping_mark'
end
