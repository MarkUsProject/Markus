describe Mark do
  it { is_expected.to validate_presence_of(:markable_type) }

  it { is_expected.to belong_to(:markable) }
  it { is_expected.to belong_to(:result) }

  it { is_expected.to allow_value('RubricCriterion').for(:markable_type) }
  it { is_expected.to allow_value('FlexibleCriterion').for(:markable_type) }
  it { is_expected.to_not allow_value('').for(:markable_type) }
  it { is_expected.to_not allow_value(nil).for(:markable_type) }
  it { is_expected.to allow_value(false).for(:override) }
  it { is_expected.to allow_value(true).for(:override) }
  it { is_expected.to_not allow_value(nil).for(:override) }

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
      expect(rubric_mark.mark).to eq(markable.weight)
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

  describe '#calculate_deduction' do
    let(:assignment) { create(:assignment_with_deductive_annotations) }
    let(:annotation_category_with_criteria) do
      assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
    end

    it 'calculates the correct deduction when one annotation is applied' do
      deducted = assignment.groupings.first.current_result.marks.first.calculate_deduction
      expect(deducted).to eq(1.0)
    end

    it 'calculates the correct deduction when multiple annotations are applied' do
      create(:text_annotation,
             annotation_text: annotation_category_with_criteria.annotation_texts.first,
             result: assignment.groupings.first.current_result)
      deducted = assignment.groupings.first.current_result.marks.first.calculate_deduction
      expect(deducted).to eq(2.0)
    end
  end

  describe '#update_deduction' do
    let(:assignment) { create(:assignment_with_deductive_annotations) }
    let(:annotation_category_with_criteria) do
      assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
    end

    it 'changes the mark correctly to reflect deductions' do
      create(:text_annotation,
             annotation_text: annotation_category_with_criteria.annotation_texts.first,
             result: assignment.groupings.first.current_result)
      assignment.reload
      expect(assignment.groupings.first.current_result.marks.first.mark).to eq(1.0)
    end

    it 'does not change the mark if override is enabled' do
      result = assignment.groupings.first.current_result
      result.marks.first.update!(mark: 3.0)
      result.marks.first.update!(override: true)
      create(:text_annotation,
             annotation_text: annotation_category_with_criteria.annotation_texts.first,
             result: result)
      assignment.reload
      expect(result.marks.first.mark).to eq(3.0)
    end

    it 'does not allow deductions to reduce the mark past 0' do
      result = assignment.groupings.first.current_result
      3.times do
        create(:text_annotation,
               annotation_text: annotation_category_with_criteria.annotation_texts.first,
               result: result)
      end
      result.reload
      expect(result.marks.first.mark).to eq(0.0)
    end
  end
  # private methods
  describe '#ensure_not_released_to_students'
  describe '#update_grouping_mark'
end
