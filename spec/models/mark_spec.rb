describe Mark do
  it { is_expected.to belong_to(:criterion) }
  it { is_expected.to belong_to(:result) }

  it { is_expected.to allow_value(false).for(:override) }
  it { is_expected.to allow_value(true).for(:override) }
  it { is_expected.not_to allow_value(nil).for(:override) }
  it { is_expected.to have_one(:course) }

  it 'should not allow associations to belong to different assignments' do
    mark = create(:rubric_mark)
    mark.criterion = create(:rubric_criterion)
    expect(subject).not_to be_valid
  end

  describe 'when mark belongs to rubric criterion and the max mark is exceeded' do
    let(:rubric_mark) do
      build(:rubric_mark, mark: 10)
    end

    it 'should not be valid' do
      expect(rubric_mark).not_to be_valid
    end
  end

  describe 'when mark belongs to flexible criterion and the max mark is exceeded' do
    let(:flexible_mark) do
      build(:flexible_mark, mark: 10)
    end

    it 'should not be valid' do
      expect(flexible_mark).not_to be_valid
    end
  end

  describe 'when mark belongs to checkbox criterion and the max mark is exceeded' do
    let(:checkbox_mark) do
      build(:checkbox_mark, mark: 10)
    end

    it 'should not be valid' do
      expect(checkbox_mark).not_to be_valid
    end
  end

  describe 'when mark is less than 0' do
    let(:rubric_mark) do
      build(:rubric_mark, mark: -1)
    end

    it 'should not be valid' do
      expect(rubric_mark).not_to be_valid
    end
  end

  describe 'mark (column in marks table)' do
    let(:rubric_mark) do
      create(:rubric_mark, mark: 4)
    end

    it 'equals to mark times max mark' do
      related_rubric = rubric_mark.criterion
      expect(rubric_mark.mark).to eq(related_rubric.max_mark)
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
    let(:result) { assignment.groupings.first.current_result }
    let(:annotation_text) { annotation_category_with_criteria.annotation_texts.first }
    let(:mark) { result.marks.first }
    let(:deductive_annotation_text) do
      create(:annotation_text_with_deduction,
             deduction: 1.5,
             annotation_category: annotation_category_with_criteria)
    end
    let(:result_with_deduction) do
      result = assignment.groupings.first.current_result
      create(:text_annotation,
             annotation_text: deductive_annotation_text,
             result: result)
      result.reload
    end

    it 'calculates the correct deduction when one annotation is applied' do
      deducted = mark.calculate_deduction
      expect(deducted).to eq(1.0)
    end

    it 'calculates the correct deduction when multiple annotations are applied' do
      create(:text_annotation,
             annotation_text: annotation_text,
             result: result)
      deducted = mark.calculate_deduction
      expect(deducted).to eq(2.0)
    end

    it 'returns 0 when override is true' do
      mark.update!(mark: 1.0, override: true)
      deducted = mark.calculate_deduction
      expect(deducted).to eq(0)
    end

    it 'returns 0 when criterion type is non flexible' do
      non_flex_mark = create(:rubric_mark)
      deducted = non_flex_mark.calculate_deduction
      expect(deducted).to eq(0)
    end

    context 'when there is a remark request' do
      let(:criterion) { deductive_annotation_text.annotation_category.flexible_criterion }
      let(:remark_result) do
        result_with_deduction.update(marking_state: Result::MARKING_STATES[:complete])
        submission = result_with_deduction.submission
        submission.make_remark_result
        submission.update(remark_request_timestamp: Time.current)
        submission.remark_result
      end

      context 'with no deductive annotations' do
        it 'returns the mark value calculated from annotation deductions of the original result' do
          mark = remark_result.marks.find_by(criterion: criterion)
          expect(mark.calculate_deduction).to eq(2.5)
        end
      end

      context 'with a deductive annotation' do
        it 'returns the mark value calculated from annotation deductions of the remark result' do
          create(:text_annotation,
                 annotation_text: deductive_annotation_text,
                 result: remark_result,
                 is_remark: true)
          mark = remark_result.marks.find_by(criterion: criterion)
          expect(mark.calculate_deduction).to eq(1.5)
        end
      end
    end
  end

  describe '#update_deduction' do
    let(:assignment) { create(:assignment_with_deductive_annotations) }
    let(:annotation_category_with_criteria) do
      assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
    end
    let(:result) { assignment.groupings.first.current_result }
    let(:annotation_text) { annotation_category_with_criteria.annotation_texts.first }
    let(:mark) { result.marks.first }

    it 'changes the mark correctly to reflect deductions when there are deductions with the same values' do
      create(:text_annotation,
             annotation_text: annotation_text,
             result: result)
      result.reload
      expect(mark.mark).to eq(1.0)
    end

    it 'changes the mark correctly to reflect deductions when there are deductions with different values' do
      new_text = create(:annotation_text_with_deduction,
                        deduction: 1.5,
                        annotation_category: annotation_category_with_criteria)
      create(:text_annotation,
             annotation_text: new_text,
             result: result)
      result.reload
      expect(mark.mark).to eq(0.5)
    end

    it 'does not change the mark if override is enabled' do
      mark.update!(mark: 3.0, override: true)
      create(:text_annotation,
             annotation_text: annotation_text,
             result: result)
      result.reload
      expect(mark.mark).to eq(3.0)
    end

    it 'does not allow deductions to reduce the mark past 0' do
      create_list(:text_annotation, 3, annotation_text: annotation_text, result: result)
      result.reload
      expect(mark.mark).to eq(0.0)
    end

    it 'does not change the mark when there are no deductions' do
      assignment_without_deductions = create(:assignment_with_criteria_and_results)
      result = assignment_without_deductions.current_results.first
      mark_without_deductions = result.marks.first
      mark_without_deductions.update_deduction
      mark_without_deductions.reload
      expect(mark_without_deductions.mark).to be_nil
    end

    it 'does not take into account deductions related to other criteria' do
      new_criterion = create(:flexible_criterion_with_annotation_category,
                             assignment: assignment)
      create(:mark,
             criterion_id: new_criterion.id,
             result: result)
      new_annotation_text = create(:annotation_text_with_deduction,
                                   annotation_category: new_criterion.annotation_categories.first)
      create(:text_annotation,
             annotation_text: new_annotation_text,
             result: result)
      mark.update_deduction
      mark.reload
      expect(mark.mark).to eq(2.0)
    end

    it 'does not update the mark to max_mark value when there are no annotations' do
      result.annotations.destroy_all # update deduction called in annotation callback
      expect(mark.reload.mark).to be_nil
    end

    it 'does not update the mark to max_mark value when there are only deductive annotations with 0 value deductions' do
      annotation_text.update!(deduction: 0) # update deduction called in annotation_text callback
      expect(mark.reload.mark).to be_nil
    end

    it 'updates the override of a mark to false when last deductive annotation deleted if the override ' \
       'was true before and the mark was nil' do
      mark.update!(mark: nil, override: true)
      result.annotations.joins(annotation_text: :annotation_category)
            .where('annotation_categories.flexible_criterion_id': mark.criterion_id).first.destroy
      expect(mark.reload.override).to be false
    end

    it 'updates the mark value to be calculated from annotation deductions if override changed to false' do
      mark.update!(override: true, mark: mark.criterion.max_mark)
      mark.update!(override: false)
      expect(mark.reload.mark).to eq 2.0
    end
  end

  describe '#deductive_annotations_absent?' do
    it 'returns true when one deductive annotation that affects this mark has been applied' do
      assignment = create(:assignment_with_deductive_annotations)
      mark = assignment.groupings.first.current_result.marks.first
      expect(mark.deductive_annotations_absent?).to be false
    end

    it 'returns true when multiple deductive annotations that affect this mark have been applied' do
      assignment = create(:assignment_with_deductive_annotations)
      result = assignment.groupings.first.current_result
      category = assignment.annotation_categories.where.not(flexible_criterion: nil).first
      create(:text_annotation, result: result, annotation_text: category.annotation_texts.first)
      mark = result.reload.marks.first
      expect(mark.deductive_annotations_absent?).to be false
    end

    it 'returns false when no deductive annotations that affect this mark have been applied' do
      assignment = create(:assignment_with_criteria_and_results)
      mark = assignment.groupings.first.current_result.marks.first
      expect(mark.deductive_annotations_absent?).to be true
    end
  end

  # private methods
  describe '#ensure_not_released_to_students'
  describe '#update_grouping_mark'
end
