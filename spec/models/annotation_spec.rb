describe Annotation do
  context 'checks relationships' do
    it { is_expected.to belong_to(:submission_file) }
    it { is_expected.to belong_to(:annotation_text) }
    it { is_expected.to belong_to(:result) }
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
    it { is_expected.to_not allow_value('OtherAnnotation').for(:type) }
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

    it 'creates a mark when associated with its category\'s flexible criterion '\
       'was made after annotations were made ' do
      annotation_text.annotations.destroy_all
      new_flex = create(:flexible_criterion, assignment: assignment)
      annotation_category.update!(flexible_criterion_id: new_flex.id)
      create(:text_annotation,
             annotation_text: annotation_text,
             result: result)
      expect(new_flex.marks.first.mark).to eq 0.67
    end
  end
end
