describe AnnotationText do
  context 'checks relationships' do
    it { is_expected.to belong_to(:annotation_category) }
    it { is_expected.to have_many(:annotations) }
    it { is_expected.to belong_to(:creator) }
    it { is_expected.to belong_to(:last_editor) }

    describe '#escape_content' do
      it 'double escapes forward slash' do
        text = create :annotation_text, content: '\\'
        expect(text.escape_content).to eq '\\\\'
      end
      it 'double converts \r\n to \\\n' do
        text = create :annotation_text, content: "\r\n"
        expect(text.escape_content).to eq '\\n'
      end
      it 'double converts \n to \\\n' do
        text = create :annotation_text, content: "\n"
        expect(text.escape_content).to eq '\\n'
      end
      it 'only converts everything in the same string properly' do
        text = create :annotation_text, content: "beginning\nmiddle\r\nmiddle2\\the end"
        expect(text.escape_content).to eq 'beginning\\nmiddle\\nmiddle2\\\\the end'
      end
    end
  end

  let(:assignment) { create(:assignment_with_deductive_annotations) }
  let(:annotation_category_with_criteria) do
    assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
  end
  let(:deductive_text) do
    annotation_category_with_criteria.annotation_texts.find_by(deduction: 1.0)
  end
  let(:category_without_criteria) { create(:annotation_category, assignment: assignment) }
  let(:text_without_deduction) { create(:annotation_text, annotation_category: category_without_criteria) }

  describe 'validation of deduction' do
    it 'is invalid with a deduction greater than the annotation_category\'s flexible_criterion\'s max mark' do
      expect(deductive_text.update(deduction: 4.0)).to be(false)
    end

    it 'is invalid with a deduction less than 0' do
      expect(deductive_text.update(deduction: -1)).to be(false)
    end

    it 'is valid with a numerical deduction if it does belong to flexible criteria through annotation category' do
      expect(deductive_text.update!(deduction: 1.0)).to be(true)
    end

    it 'is invalid with a nil deduction if it does belong to flexible criteria through annotation category' do
      expect(deductive_text.update(deduction: nil)).to be(false)
    end

    it 'is valid with a nil deduction if it does not belong to flexible criteria through annotation category' do
      expect(text_without_deduction).to be_valid
    end

    it 'is invalid with a numerical deduction if it does not belong to flexible criteria through annotation category' do
      expect(text_without_deduction.update(deduction: 3.0)).to be(false)
    end
  end

  describe 'callbacks' do
    it 'prevent an update of deduction if any results are released', :je do
      assignment.groupings.first.current_result.update!(released_to_students: true)
      expect(deductive_text.update(deduction: 2.0)).to be(false)
    end

    it 'prevent an update of content if any results are released and there is a deduction' do
      assignment.groupings.first.current_result.update!(released_to_students: true)
      expect(deductive_text.update(content: 'Do not plagiarize!')).to be(false)
    end

    it 'does not prevent an update of content if any results are released and there is no deduction' do
      expect(deductive_text.update(content: 'Do not plagiarize!')).to be(true)
    end
  end

  describe '#update_mark_deductions' do
    it 'updates the mark associated with its annotation category\'s flexible criterion' \
       'for every grouping if the its deduction changed' do
      deductive_text.update!(deduction: 2.0)
      assignment.reload
      marks = []
      assignment.groupings.includes(:current_result).each do |grouping|
        marks << grouping.current_result
                         .marks
                         .find_by(markable_id: annotation_category_with_criteria.flexible_criterion_id).mark
      end
      expect(marks).to eq([1.0, 1.0, 1.0])
    end

    it 'returns without updating marks if its annotation category doesn\'t belong to a flexible criterion' do
      previous_marks = []
      assignment.groupings.includes(:current_result).each do |grouping|
        previous_marks << grouping.current_result
                                  .marks
                                  .find_by(markable_id: annotation_category_with_criteria.flexible_criterion_id).mark
      end
      create(:text_annotation,
             annotation_text: text_without_deduction,
             result: assignment.groupings.first.current_result)
      text_without_deduction.update!(content: 'Do not plagiarize!')
      new_marks = []
      assignment.groupings.includes(:current_result).each do |grouping|
        new_marks << grouping.current_result
                             .marks
                             .find_by(markable_id: annotation_category_with_criteria.flexible_criterion_id).mark
      end
      expect(new_marks).to eq(previous_marks)
    end

    it 'returns without updating marks if its deduction was not changed' do
      deductive_text.update!(content: 'Do not plagiarize!')
      assignment.reload
      marks = []
      assignment.groupings.includes(:current_result).each do |grouping|
        marks << grouping.current_result
                     .marks
                     .find_by(markable_id: annotation_category_with_criteria.flexible_criterion_id).mark
      end
      expect(marks).to eq([2.0, 2.0, 2.0])
    end
  end

  describe '#scale_deduction' do
    it 'correctly scales deduction when called from flexible criteria' do
      assignment.flexible_criteria.first.update!(max_mark: 5)
      assignment.reload
      expect(assignment.annotation_categories.first.annotation_texts.first.deduction).to eq(1.67)
    end

    it 'correctly scales deduction when called from annotation category' do
      new_criterion = create(:flexible_criterion, assignment: assignment)
      assignment.annotation_categories.first.update!(flexible_criterion_id: new_criterion.id)
      assignment.reload
      expect(assignment.annotation_categories.first.annotation_texts.first.deduction).to eq(0.33)
    end

    it 'does not affect the deduction when deduction is nil' do

    end

    it 'triggers update_mark_deductions to be called after it successfully executes' do

    end

    it 'does not affect the deduction when results have released' do

    end
  end
end
