describe Annotation do
  context 'checks relationships' do
    it { is_expected.to belong_to(:submission_file) }
    it { is_expected.to belong_to(:annotation_text) }
    it { is_expected.to belong_to(:result) }
    it { is_expected.to have_one(:course) }
  end

  context 'requires items to be set' do
    it { is_expected.to validate_presence_of(:annotation_number) }
  end

  context 'validates certain values' do
    it { is_expected.to validate_numericality_of(:annotation_number) }
  end

  context 'ensures invalid values cannot be added' do
    it { is_expected.to_not allow_value(-1).for(:annotation_number) }

    it { is_expected.to allow_value('ImageAnnotation').for(:type) }
    it { is_expected.to allow_value('TextAnnotation').for(:type) }
    it { is_expected.to allow_value('PdfAnnotation').for(:type) }
    it { is_expected.to allow_value('HtmlAnnotation').for(:type) }
    it { is_expected.to_not allow_value('OtherAnnotation').for(:type) }
  end

  context 'creating annotations' do
    let(:assignment) { create(:assignment_with_criteria_and_results) }
    context 'with a remark result' do
      let(:result) do
        grouping = assignment.groupings.first
        grouping.current_result.update!(released_to_students: true)
        grouping.current_submission_used.make_remark_result
        grouping.current_result
      end
      it 'should allow it to be created' do
        expect { create(:text_annotation, result: result, is_remark: true) }.not_to raise_error
      end
    end
    context 'with a released result' do
      let(:annotation) { create(:text_annotation, result: create(:released_result)) }
      it 'should prevent it being created' do
        expect { annotation }.to raise_error(ActiveRecord::RecordNotSaved)
      end
    end
    context 'without remark result or a released result' do
      it 'should prevent it being created' do
        expect { create(:text_annotation) }.not_to raise_error
      end
    end
  end
  context 'destroying annotations' do
    let(:assignment) { create(:assignment_with_criteria_and_results) }
    context 'with a remark result' do
      let(:annotation) do
        grouping = assignment.groupings.first
        annotation = create(:text_annotation, result: grouping.current_result)
        grouping.current_result.update!(released_to_students: true)
        grouping.current_submission_used.make_remark_result
        annotation
      end
      it 'should prevent a pre-existing annotation from being destroyed' do
        expect { annotation.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
      it 'should allow a remark annotation to destroyed' do
        annotation.update!(is_remark: true)
        expect { annotation.destroy! }.not_to raise_error
      end
    end
    context 'with a released result' do
      let(:annotation) { create(:text_annotation) }
      it 'should prevent it being destroyed' do
        annotation.result.update!(released_to_students: true)
        expect { annotation.reload.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end
    context 'without remark result or a released result' do
      let(:annotation) { create(:text_annotation) }
      it 'should prevent it being destroyed' do
        expect { annotation.reload.destroy! }.not_to raise_error
      end
    end
  end

  context 'when associated with a deduction' do
    let(:assignment) { create(:assignment_with_deductive_annotations) }
    let(:annotation_category) { assignment.annotation_categories.where.not(flexible_criterion_id: nil).first }
    let(:annotation_text) { annotation_category.annotation_texts.first }
    let(:result) { assignment.groupings.first.current_result }
    let(:mark) { result.marks.find_by(criterion_id: annotation_category.flexible_criterion_id) }

    it 'correctly updates the mark when created' do
      create(:text_annotation,
             annotation_text: annotation_text,
             result: result)
      expect(mark.mark).to eq 1.0
    end

    it 'correctly updates the mark when destroyed, being only deductive annotation applied' do
      result.annotations.find_by(annotation_text: annotation_text).destroy
      expect(mark.mark).to eq nil
    end

    it 'correctly updates the mark when destroyed, being one of several deductive annotations applied' do
      create(:text_annotation,
             annotation_text: annotation_text,
             result: result)
      result.annotations.find_by(annotation_text: annotation_text).destroy
      expect(mark.mark).to eq 2.0
    end

    it 'creates a mark when associated with its category\'s flexible criterion ' \
       'was made after annotations were made ' do
      annotation_text.annotations.destroy_all
      new_flex = create(:flexible_criterion, assignment: assignment)
      annotation_category.update!(flexible_criterion_id: new_flex.id)
      create(:text_annotation,
             annotation_text: annotation_text,
             result: result)
      expect(new_flex.marks.first.mark).to eq 0.67
    end

    context 'with a remark request' do
      let(:annotation) do
        grouping = assignment.groupings.first
        grouping.current_result.update!(released_to_students: true)
        grouping.current_submission_used.make_remark_result
        grouping.current_submission_used.update!(remark_request: 'remark request',
                                                 remark_request_timestamp: Time.current)
        grouping.current_submission_used.get_original_result.update!(released_to_students: false)
        annotation = create(:text_annotation, annotation_text: annotation_text, result: grouping.current_result,
                                              is_remark: true)
        annotation
      end
      it 'does not update a mark after creation' do
        expect(mark.mark).to eq 2.0
      end
      it 'does not update a mark after destruction' do
        annotation.destroy!
        expect(mark.mark).to eq 2.0
      end
    end
  end
end
