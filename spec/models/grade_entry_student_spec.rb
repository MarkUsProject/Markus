require 'spec_helper'

describe GradeEntryStudent do
  describe 'assigning and unassigning TAs' do
    let(:form) { create(:grade_entry_form) }
    let(:students) { Array.new(2) { create(:student) } }
    let(:tas) { Array.new(2) { create(:ta) } }
    let(:student_ids) { students.map(&:id) }
    let(:ta_ids) { tas.map(&:id) }

    describe '.randomly_assign_tas' do
      it 'can randomly bulk assign no TAs to no grade_entry_students' do
        GradeEntryStudent.randomly_assign_tas([], [], form)
      end

      it 'can randomly bulk assign TAs to no grade entry students' do
        GradeEntryStudent.randomly_assign_tas([], ta_ids, form)
      end

      it 'can randomly bulk assign no TAs to all grade entry students' do
        GradeEntryStudent.randomly_assign_tas(student_ids, [], form)
      end

      it 'can randomly bulk assign TAs to all grade entry students' do
        GradeEntryStudent.randomly_assign_tas(student_ids, ta_ids, form)

        form.grade_entry_students.each do |ges|
          ges.reload
          expect(ges.tas.size).to eq 1
          expect(tas).to include ges.tas.first
        end
      end

      it 'can randomly bulk assign duplicated TAs to grade entry students' do
        # The probability of assigning no duplicated TAs after (tas.size + 1)
        # trials is 0.
        (tas.size + 1).times do
          GradeEntryStudent.randomly_assign_tas(student_ids, ta_ids, form)
        end

        ta_set = tas.to_set
        form.grade_entry_students.each do |grade_entry_student|
          grade_entry_student.reload
          expect(grade_entry_student.tas.size).to be_between(1, 2).inclusive
          expect(grade_entry_student.tas.to_set).to be_subset(ta_set)
        end
      end
    end

    describe '.assign_all_tas' do
      it 'can bulk assign no TAs to no grade entry students' do
        GradeEntryStudent.assign_all_tas([], [], form)
      end

      it 'can bulk assign all TAs to no grade entry students' do
        GradeEntryStudent.assign_all_tas([], ta_ids, form)
      end

      it 'can bulk assign no TAs to all grade entry students' do
        GradeEntryStudent.assign_all_tas(student_ids, [], form)
      end

      it 'can bulk assign all TAs to all grade entry students' do
        GradeEntryStudent.assign_all_tas(student_ids, ta_ids, form)

        form.grade_entry_students.each do |grade_entry_student|
          grade_entry_student.reload
          expect(grade_entry_student.tas).to match_array(tas)
        end
      end

      it 'can bulk assign duplicated TAs to grade entry students' do
        GradeEntryStudent.assign_all_tas(student_ids.first, ta_ids, form)
        GradeEntryStudent.assign_all_tas(student_ids, ta_ids.first, form)

        # First grade entry student gets all the TAs.
        grade_entry_student = form.grade_entry_students.first
        grade_entry_student.reload
        form.grade_entry_students.delete(grade_entry_student)
        expect(grade_entry_student.tas).to match_array(tas)

        # The rest of the grade entry students gets only the first TA.
        form.grade_entry_students.each do |ges|
          ges.reload
          expect(ges.tas).to eq [tas.first]
        end
      end
    end

    describe '.unassign_tas' do
      it 'can bulk unassign no TAs' do
        GradeEntryStudent.unassign_tas([])
      end

      it 'can bulk unassign TAs' do
        GradeEntryStudent.assign_all_tas(student_ids, ta_ids, form)
        gest_ids = form.grade_entry_students.map do |grade_entry_student|
          grade_entry_student.grade_entry_student_tas.pluck(:id)
        end.reduce(:+)
        GradeEntryStudent.unassign_tas(gest_ids)

        form.grade_entry_students.each do |grade_entry_student|
          grade_entry_student.reload
          expect(grade_entry_student.tas).to be_empty
        end
      end
    end
  end
end
