describe AnnotationText do
  let(:flexible_criterion) { annotation_category_with_criterion.flexible_criterion }
  let(:text_without_deduction) { create(:annotation_text, annotation_category: category_without_criteria) }
  let(:category_without_criteria) { create(:annotation_category, assignment: assignment) }
  let(:deductive_text) do
    annotation_category_with_criterion.annotation_texts.where.not(deduction: nil).first
  end
  let(:annotation_category_with_criterion) do
    assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
  end
  let(:assignment) { create(:assignment_with_deductive_annotations) }

  context 'checks relationships' do
    subject { create(:annotation_text) }

    it { is_expected.to belong_to(:annotation_category).optional }
    it { is_expected.to have_many(:annotations) }
    it { is_expected.to belong_to(:creator) }
    it { is_expected.to belong_to(:last_editor).optional }
    it { is_expected.to have_one(:course) }

    it_behaves_like 'course associations'

    describe '#escape_content' do
      it 'double escapes forward slash' do
        text = create(:annotation_text, content: '\\')
        expect(text.escape_content).to eq '\\\\'
      end

      it 'double converts \r\n to \\\n' do
        text = create(:annotation_text, content: "\r\n")
        expect(text.escape_content).to eq '\\n'
      end

      it 'double converts \n to \\\n' do
        text = create(:annotation_text, content: "\n")
        expect(text.escape_content).to eq '\\n'
      end

      it 'only converts everything in the same string properly' do
        text = create(:annotation_text, content: "beginning\nmiddle\r\nmiddle2\\the end")
        expect(text.escape_content).to eq 'beginning\\nmiddle\\nmiddle2\\\\the end'
      end
    end
  end

  describe 'validation of deduction' do
    it 'is invalid with a deduction greater than the annotation_category\'s flexible_criterion\'s max mark' do
      deductive_text.deduction = 4.0
      expect(deductive_text).not_to be_valid
    end

    it 'is invalid with a deduction less than 0' do
      deductive_text.deduction = -1.0
      expect(deductive_text).not_to be_valid
    end

    it 'is valid with a numerical deduction if it does belong to flexible criteria through annotation category' do
      expect(deductive_text).to be_valid
    end

    it 'is invalid with a nil deduction if it does belong to flexible criteria through annotation category' do
      deductive_text.deduction = nil
      expect(deductive_text).not_to be_valid
    end

    it 'is valid with a nil deduction if it does not belong to flexible criteria through annotation category' do
      expect(text_without_deduction).to be_valid
    end

    it 'is invalid with a numerical deduction if it does not belong to flexible criteria through annotation category' do
      text_without_deduction.deduction = 1.0
      expect(text_without_deduction).not_to be_valid
    end
  end

  describe 'callbacks' do
    context 'results are released' do
      before { assignment.groupings.first.current_result.update!(released_to_students: true) }

      it 'prevents an update to the deduction' do
        expect(deductive_text.update(deduction: 2.0)).to be false
      end

      it 'prevents an update to the content' do
        expect(deductive_text.update(content: 'Do not plagiarize!')).to be false
      end

      it 'prevents deletion' do
        expect(deductive_text.destroy).to be false
      end
    end

    context 'results are not released and no remark request exists' do
      it 'does not prevent an update to the deduction' do
        expect(deductive_text.update(deduction: 2.0)).to be true
      end

      it 'does not prevent an update to the content' do
        expect(deductive_text.update(content: 'Do not plagiarize!')).to be true
      end

      it 'does not prevent deletion' do
        expect(deductive_text.destroy).to eq deductive_text
      end
    end

    context 'a remark request exists' do
      before do
        grouping = assignment.groupings.first
        grouping.current_result.update!(released_to_students: true)
        grouping.current_submission_used.make_remark_result
      end

      it 'prevents an update to the deduction' do
        expect(deductive_text.update(deduction: 2.0)).to be false
      end

      it 'prevents an update to the content' do
        expect(deductive_text.update(content: 'Do not plagiarize!')).to be false
      end

      it 'prevents deletion' do
        expect(deductive_text.destroy).to be false
      end
    end
  end

  describe '#update_mark_deductions' do
    it 'updates the mark associated with its annotation category\'s flexible criterion ' \
       'for every grouping if its deduction changed' do
      deductive_text.update!(deduction: 2.0)
      assignment.reload
      marks = assignment.groupings.includes(:current_result).map do |grouping|
        grouping.current_result.marks.find_by(criterion: flexible_criterion).mark
      end
      expect(marks).to eq [1.0, 1.0, 1.0]
    end

    it 'returns without updating marks if its annotation category doesn\'t belong to a flexible criterion' do
      previous_marks = assignment.groupings.includes(:current_result).map do |grouping|
        grouping.current_result.marks.find_by(criterion: flexible_criterion).mark
      end
      create(:text_annotation,
             annotation_text: text_without_deduction,
             result: assignment.groupings.first.current_result)
      text_without_deduction.update!(content: 'Do not plagiarize!')
      new_marks = assignment.groupings.includes(:current_result).map do |grouping|
        grouping.current_result.marks.find_by(criterion: flexible_criterion).mark
      end
      expect(new_marks).to eq previous_marks
    end

    it 'returns without updating marks if its deduction was not changed' do
      deductive_text.update!(content: 'Do not plagiarize!')
      assignment.reload
      marks = assignment.groupings.includes(:current_result).map do |grouping|
        grouping.current_result.marks.find_by(criterion: flexible_criterion).mark
      end
      expect(marks).to eq [2.0, 2.0, 2.0]
    end

    it 'creates marks if criterion was created after annotation texts' do
      old_criterion = flexible_criterion
      new_flex = create(:flexible_criterion, assignment: assignment)
      annotation_category_with_criterion.update!(flexible_criterion_id: new_flex.id)
      assignment.reload
      prev_criterion_marks = []
      new_criterion_marks = []
      assignment.groupings.includes(:current_result).map do |grouping|
        prev_criterion_marks << grouping.current_result.marks.find_by(criterion: old_criterion).mark
        new_criterion_marks << grouping.current_result.marks.find_by(criterion: new_flex).mark
      end
      expect(prev_criterion_marks).to eq [nil, nil, nil]
      expect(new_criterion_marks).to eq [0.67, 0.67, 0.67]
    end
  end

  describe '#scale_deduction' do
    it 'does not affect the deduction when deduction is nil' do
      text_without_deduction.scale_deduction(2.0)
      expect(text_without_deduction.deduction).to be_nil
    end

    it 'triggers update_mark_deductions to be called after it successfully executes' do
      deductive_text.scale_deduction(2.0)
      assignment.reload
      marks = assignment.groupings.includes(:current_result).map do |grouping|
        grouping.current_result.marks.find_by(criterion: flexible_criterion).mark
      end
      expect(marks).to eq [1.0, 1.0, 1.0]
    end

    it 'does not affect the deduction when results have released' do
      assignment.groupings.first.current_result.update!(released_to_students: true)
      expect { deductive_text.scale_deduction(2.0) }.to raise_error ActiveRecord::RecordNotSaved
    end
  end
end
