describe GradeEntryStudentTa do
  describe 'validations' do
    subject do
      create(:grade_entry_form)
      student = create(:student)
      create(:grade_entry_student_ta, grade_entry_student: student.grade_entry_students.first)
    end

    it { is_expected.to have_one(:course) }

    it_behaves_like 'course associations'
  end
end
