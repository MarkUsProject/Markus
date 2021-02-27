describe GradeEntryStudent do
  it { is_expected.to callback(:update_results).after(:save) }
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
        GradeEntryStudent.unassign_tas([], [], form)
      end

      it 'can bulk unassign TAs' do
        GradeEntryStudent.assign_all_tas(student_ids, ta_ids, form)
        GradeEntryStudent.unassign_tas(student_ids, ta_ids, form)

        form.grade_entry_students.each do |grade_entry_student|
          grade_entry_student.reload
          expect(grade_entry_student.tas).to be_empty
        end
      end
    end
  end
  context 'self.refresh_total_grades' do
    let(:form) { create(:grade_entry_form) }
    let(:grade_entry_items) { create_list(:grade_entry_item, 3, grade_entry_form: form) }
    let!(:students) { create_list :student, 3 }
    let(:grade_entry_student_ids) { form.grade_entry_students.map(&:id) }
    before do
      form.grade_entry_students.map do |ges|
        grade_entry_items.each_with_index.map do |gei, ind|
          create :grade, grade_entry_item: gei, grade_entry_student: ges, grade: grades[ind]
        end
      end
    end
    describe 'when no grades are nil' do
      let(:grades) { [1, 1, 1] }
      it 'updates the total_grade' do
        GradeEntryStudent.refresh_total_grades(grade_entry_student_ids)
        form.grade_entry_students.each do |ges|
          expect(ges.reload.total_grade).to eq 3
        end
      end
    end
    describe 'when the grades are all nil' do
      let(:grades) { [nil, nil, nil] }
      it 'updates the total_grade to nil' do
        GradeEntryStudent.refresh_total_grades(grade_entry_student_ids)
        form.grade_entry_students.each do |ges|
          expect(ges.reload.total_grade).to be_nil
        end
      end
    end
    describe 'when some grades are nil' do
      let(:grades) { [nil, 1, 1] }
      it 'updates the total_grade to nil' do
        GradeEntryStudent.refresh_total_grades(grade_entry_student_ids)
        form.grade_entry_students.each do |ges|
          expect(ges.reload.total_grade).to eq 2
        end
      end
    end
  end
  context 'self.update_results' do
    let(:form) { create(:grade_entry_form) }
    let(:grade_entry_items) { create_list(:grade_entry_item, 3, grade_entry_form: form) }
    let!(:students) { create_list :student, 3 }
    let(:grade_entry_student_ids) { form.grade_entry_students.map(&:id) }
    before do
      form.grade_entry_students.map do |ges|
        grade_entry_items.each_with_index.map do |gei, ind|
          create :grade, grade_entry_item: gei, grade_entry_student: ges, grade: grades[ind]
        end
        ges.save
      end
    end
    describe 'when no grades are nil' do
      let(:grades) { [1, 1, 1] }
      it 'updates the total_grade' do
        print(form.reload.attributes)
        expect(form.reload.results_average).to eq 1
        expect(form.reload.results_median).to eq 1
      end
    end
    describe 'when median and average are different' do
      let(:grades) { [1, 2, 3] }
      it 'updates the total_grade' do
        expect(form.reload.results_average).to eq 2
        expect(form.reload.results_median).to eq 2
      end
    end
    describe 'when all grades are nil' do
      let(:grades) { [nil, nil, nil] }
      it 'updates the total_grade' do
        expect(form.reload.results_average).to eq 0
        expect(form.reload.results_median).to eq 0
      end
    end
  end
end
