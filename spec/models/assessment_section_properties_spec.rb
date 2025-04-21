describe AssessmentSectionProperties do
  describe 'ActiveRecord associations' do
    subject { create(:assessment_section_properties) }

    it { is_expected.to belong_to(:section) }
    it { is_expected.to belong_to(:assessment) }
    it { is_expected.to have_one(:course) }

    it_behaves_like 'course associations'
  end

  describe '.due_date_for(section, assignment)' do
    context 'when an assignment has SectionDueDates disabled' do
      before do
        @assignment = create(:assignment,
                             due_date: 2.days.from_now,
                             assignment_properties_attributes: { section_due_dates_type: false })
      end

      it 'returns the due date of the assignment' do
        due_date = AssessmentSectionProperties.due_date_for(create(:section), @assignment)
        expect(due_date.day).to eq 2.days.from_now.day
      end
    end

    context 'when an assignment has SectionDueDates enabled' do
      before do
        @assignment = create(:assignment,
                             due_date: 2.days.from_now,
                             assignment_properties_attributes: { section_due_dates_type: true })
      end

      context 'and the section does not have a due date set' do
        it 'returns the due date of the assignment' do
          due_date = AssessmentSectionProperties.due_date_for(create(:section), @assignment)
          expect(due_date.day).to eq 2.days.from_now.day
        end
      end

      context 'and the section has a due date set' do
        before do
          @section = create(:section)
          AssessmentSectionProperties.create(section: @section,
                                             assessment: @assignment,
                                             due_date: 1.day.from_now)
        end

        it 'returns the due date for the section of the assignment' do
          due_date = AssessmentSectionProperties.due_date_for(@section, @assignment)
          expect(due_date.day).to eq 1.day.from_now.day
        end
      end
    end
  end
end
