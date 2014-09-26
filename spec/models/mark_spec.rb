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
			let(:mark) { create(:mark, mark: 4, markable_type: 'RubricCriterion') }

			it "is valid to have rubric briterion mark smaller or equal to four" do
				expect(mark.valid_mark).to be_truthy
			end
  	end

  	context 'when markable type is flexible' do
  	end

  end

  describe '#get_mark' do

  end

  #no need to test private methods
  describe '#ensure_not_released_to_students'
  describe '#update_grouping_mark'
end