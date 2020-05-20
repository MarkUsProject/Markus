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
    # have separate tests within this to check if with deduction or not
  end

  describe 'callbacks' do
    # have separate tests within this to check if with deduction or not
    # should check that when update is called check_if_released is run
  end

  describe '#update_mark_deductions' do
    #have separate tests within this to check if with deduction or not
    # should check update_mark_deductions if deduction changes,
    # should check update_mark_deductions returns if deduction isnt changed
    # .valid?
    it 'does not get called if any results are released' do
      assignment.groupings.first.current_result.released_to_students = true
      assignment.annotation_categories.first.annotation_texts.first.update!(deduction: 2.0)
      expect(assignment.groupings.first.current_result.marks.first.mark).to eq(2.0)
    end

    it 'updates the mark associated with its annotation category\'s flexible criterion for every grouping' do
      assignment.annotation_categories.first.annotation_texts.first.update!(deduction: 2.0)
      assignment.reload
      marks = []
      marks << assignment.groupings[0].current_result.marks.first.mark
      marks << assignment.groupings[1].current_result.marks.first.mark
      marks << assignment.groupings[2].current_result.marks.first.mark
      expect(marks).to eq([1.0, 1.0, 1.0])
    end

    it 'returns without updating marks if its annotation category\'s doesn\'t belong to a flexible criterion' do
      assignment.annotation_categories << create(:annotation_category)
      assignment.annotation_categories[1].annotation_texts << create(:annotation_text)
      assignment.groupings
                .first.current_result
                .annotations << create(:text_annotation,
                                       annotation_text: assignment.annotation_categories.first.annotation_texts.first,
                                       result: assignment.groupings.first.current_result)
      assignment.annotation_categories.first.annotation_texts.first.update!(content: 'Do not plagiarize!')
      expect(assignment.groupings.first.current_result.marks.first.mark).to eq(2.0)
    end

    it 'returns without updating marks if its deduction was not changed' do
      assignment.annotation_categories.first.annotation_texts.first.update!(content: 'Do not plagiarize!')
      expect(assignment.groupings.first.current_result.marks.first.mark).to eq(2.0)
    end

    it 'updates marks to nil if its annotation_category has its flexible_criterion disassociated from it' do
      assignment.annotation_categories.first.update!(flexible_criterion_id: nil)
      assignment.reload

      marks = []
      marks << assignment.groupings[0].current_result.marks.first.mark
      marks << assignment.groupings[1].current_result.marks.first.mark
      marks << assignment.groupings[2].current_result.marks.first.mark
      expect(marks).to eq([3.0, 3.0, 3.0])
    end
  end

  describe '#scale_deduction' do
    # have separate tests within this to check if with deduction or not
    # should check that scale deduction only happens if there is no marks released
    # should check that the scale is right
    # should check that update_mark_deductions is subsequently called as well
  end
end
