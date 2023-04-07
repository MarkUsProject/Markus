describe Grade do
  context 'when it is not a bonus grade' do
    subject do
      grade_entry_form = create :grade_entry_form
      student = create :student
      grade_entry_item = create :grade_entry_item, bonus: false, grade_entry_form: grade_entry_form
      create :grade, grade_entry_student: student.grade_entry_students.first, grade_entry_item: grade_entry_item
    end

    it { is_expected.to belong_to(:grade_entry_item) }
    it { is_expected.to belong_to(:grade_entry_student) }
    it { is_expected.to have_one(:course) }
    include_examples 'course associations'

    it { is_expected.to allow_value(0.0).for(:grade) }
    it { is_expected.to allow_value(1.5).for(:grade) }
    it { is_expected.to allow_value(100.0).for(:grade) }
    it { is_expected.to_not allow_value(-0.5).for(:grade) }
    it { is_expected.to_not allow_value(-1.0).for(:grade) }
    it { is_expected.to_not allow_value(-100.0).for(:grade) }
  end

  context 'when it is a bonus grade' do
    subject do
      grade_entry_form = create :grade_entry_form
      student = create :student
      grade_entry_item = create :grade_entry_item, bonus: true, grade_entry_form: grade_entry_form
      create :grade, grade_entry_student: student.grade_entry_students.first, grade_entry_item: grade_entry_item
    end

    it { is_expected.to belong_to(:grade_entry_item) }
    it { is_expected.to belong_to(:grade_entry_student) }
    it { is_expected.to have_one(:course) }
    include_examples 'course associations'

    it { is_expected.to allow_value(0.0).for(:grade) }
    it { is_expected.to allow_value(1.5).for(:grade) }
    it { is_expected.to allow_value(100.0).for(:grade) }
    it { is_expected.to allow_value(-0.5).for(:grade) }
    it { is_expected.to allow_value(-1.0).for(:grade) }
    it { is_expected.to allow_value(-100.0).for(:grade) }
  end
end
