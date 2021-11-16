describe GradeEntryStudentTa do
  describe 'validations' do
    subject { create :grade_entry_student_ta }
    it { is_expected.to have_one(:course) }
    include_examples 'course associations'
  end
end
