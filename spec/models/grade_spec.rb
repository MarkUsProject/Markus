describe Grade do
  subject do
    create :grade_entry_form
    student = create :student
    create :grade, grade_entry_student: student.grade_entry_students.first
  end
  it { is_expected.to validate_numericality_of(:grade) }

  it { is_expected.to allow_value(0.0).for(:grade) }
  it { is_expected.to allow_value(1.5).for(:grade) }
  it { is_expected.to allow_value(100.0).for(:grade) }
  it { is_expected.to allow_value(-0.5).for(:grade) }
  it { is_expected.to allow_value(-1.0).for(:grade) }
  it { is_expected.to allow_value(-100.0).for(:grade) }

  it { is_expected.to belong_to(:grade_entry_item) }
  it { is_expected.to belong_to(:grade_entry_student) }
  it { is_expected.to have_one(:course) }
  include_examples 'course associations'
end
