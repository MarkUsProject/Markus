describe Grade do
  subject do
    create(:grade_entry_form)
    student = create(:student)
    create(:grade, grade_entry_student: student.grade_entry_students.first)
  end

  it { is_expected.to belong_to(:grade_entry_item) }
  it { is_expected.to belong_to(:grade_entry_student) }
  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'

  context 'when it is not a bonus grade' do
    subject do
      student = create(:student)
      grade_entry_item = create(:grade_entry_item, bonus: false)
      create(:grade, grade_entry_student: student.grade_entry_students.first, grade_entry_item: grade_entry_item)
    end

    it { is_expected.to allow_value(0.0).for(:grade) }
    it { is_expected.to allow_value(1.5).for(:grade) }
    it { is_expected.to allow_value(100.0).for(:grade) }
    it { is_expected.not_to allow_value(-0.5).for(:grade) }
    it { is_expected.not_to allow_value(-1.0).for(:grade) }
    it { is_expected.not_to allow_value(-100.0).for(:grade) }
  end

  context 'when it is a bonus grade' do
    subject do
      student = create(:student)
      grade_entry_item = create(:grade_entry_item, bonus: true)
      create(:grade, grade_entry_student: student.grade_entry_students.first, grade_entry_item: grade_entry_item)
    end

    it { is_expected.to allow_value(0.0).for(:grade) }
    it { is_expected.to allow_value(1.5).for(:grade) }
    it { is_expected.to allow_value(100.0).for(:grade) }
    it { is_expected.to allow_value(-0.5).for(:grade) }
    it { is_expected.to allow_value(-1.0).for(:grade) }
    it { is_expected.to allow_value(-100.0).for(:grade) }
  end
end
