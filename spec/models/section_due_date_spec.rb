require 'spec_helper'

describe SectionDueDate do
  describe 'ActiveRecord associations' do
    it { is_expected.to belong_to(:section) }
    it { is_expected.to belong_to(:assignment) }
  end

  describe '.due_date_for(section, assignment)' do
    context 'when an assignment has SectionDueDates disabled' do
      before :each do
        @assignment = create(:assignment,
                             section_due_dates_type: false,
                             due_date: 2.days.from_now)
      end

      it 'returns the due date of the assignment' do
        due_date = SectionDueDate.due_date_for(create(:section), @assignment)
        expect(due_date.day).to eq 2.days.from_now.day
      end
    end

    context 'when an assignment has SectionDueDates enabled' do
      before :each do
        @assignment = create(:assignment,
                             section_due_dates_type: true,
                             due_date: 2.days.from_now)
      end

      context 'and the section does not have a due date set' do
        it 'returns the due date of the assignment' do
          due_date = SectionDueDate.due_date_for(create(:section), @assignment)
          expect(due_date.day).to eq 2.days.from_now.day
        end
      end

      context 'and the section has a due date set' do
        before :each do
          @section = create(:section)
          SectionDueDate.create(section: @section,
                                assignment: @assignment,
                                due_date: 1.days.from_now)
        end

        it 'returns the due date for the section of the assignment' do
          due_date = SectionDueDate.due_date_for(@section, @assignment)
          expect(due_date.day).to eq 1.days.from_now.day
        end
      end
    end
  end
end
