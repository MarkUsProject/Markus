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

  describe 'validation of deduction' do
    it 'is invalid with a deduction greater than the annotation_category\'s flexible_criterion\'s max mark' do
      expect { assignment.annotation_categories.first.annotation_texts.first.update!(deduction: 4.0) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'is invalid with a deduction less than 0' do
      text = assignment.annotation_categories.first.annotation_texts.first
      expect { text.update!(deduction: -1) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'is valid with a numerical deduction' do
      text = assignment.annotation_categories.first.annotation_texts.first
      expect { text.update!(deduction: 1.0) }.to_not raise_error(ActiveRecord::RecordInvalid)
    end

    it 'is valid with a nil deduction if does not belong to flexible criteria through annotation category' do
      assignment.annotation_categories << create(:annotation_category)
      assignment.annotation_categories[1].annotation_texts << create(:annotation_text)
      expect(assignment.annotation_categories[1].annotation_texts.first).to be_valid
    end
  end

  describe 'callbacks' do
    it 'prevent an update of deduction if any results are released', :je do
      assignment.groupings.first.current_result.update!(released_to_students: true)
      text = assignment.annotation_categories.first.annotation_texts.first
      expect { text.update!(deduction: 2.0) }.to raise_error(ActiveRecord::RecordNotSaved)
    end

    it 'prevent an update of content if any results are released and there is a deduction' do
      assignment.groupings.first.current_result.update!(released_to_students: true)
      text = assignment.annotation_categories.first.annotation_texts.first
      expect { text.update!(content: 'Do not plagiarize!') }.to raise_error(ActiveRecord::RecordNotSaved)
    end

    it 'does not prevent an update of content if any results are released and there is no deduction' do
      text = assignment.annotation_categories.first.annotation_texts.first
      expect { text.update!(content: 'Do not plagiarize!') }.to_not raise_error(ActiveRecord::RecordNotSaved)
    end
  end

  describe '#update_mark_deductions' do
    it 'updates the mark associated with its annotation category\'s flexible criterion' \
       'for every grouping if the its deduction changed' do
      assignment.annotation_categories.first.annotation_texts.first.update!(deduction: 2.0)
      assignment.reload
      marks = []
      marks << assignment.groupings[0].current_result.marks.first.mark
      marks << assignment.groupings[1].current_result.marks.first.mark
      marks << assignment.groupings[2].current_result.marks.first.mark
      expect(marks).to eq([1.0, 1.0, 1.0])
    end

    it 'returns without updating marks if its annotation category doesn\'t belong to a flexible criterion' do
      assignment.annotation_categories << create(:annotation_category)
      assignment.annotation_categories[1].annotation_texts << create(:annotation_text)
      assignment.groupings
                .first.current_result
                .annotations << create(:text_annotation,
                                       annotation_text: assignment.annotation_categories.first.annotation_texts.first,
                                       result: assignment.groupings.first.current_result)
      assignment.annotation_categories[1].annotation_texts.first.update!(content: 'Do not plagiarize!')
      expect(assignment.groupings.first.current_result.marks.first.mark).to eq(2.0)
    end

    it 'returns without updating marks if its deduction was not changed' do
      assignment.annotation_categories.first.annotation_texts.first.update!(content: 'Do not plagiarize!')
      assignment.reload
      marks = []
      marks << assignment.groupings[0].current_result.marks.first.mark
      marks << assignment.groupings[1].current_result.marks.first.mark
      marks << assignment.groupings[2].current_result.marks.first.mark
      expect(marks).to eq([2.0, 2.0, 2.0])
    end
  end

  describe '#scale_deduction' do
    it 'correctly scales deduction when called from flexible criteria' do
      assignment.flexible_criteria.first.update!(max_mark: 5)
      assignment.reload
      expect(assignment.annotation_categories.first.annotation_texts.first.deduction).to eq(1.67)
    end

    it 'correctly scales deduction when called from annotation category', :lol do
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
