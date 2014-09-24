describe Grade do

  it do
    is_expected.to validate_numericality_of(:grade)
    .with_message(I18n.t('grade_entry_forms.invalid_grade'))
  end
  it do
    is_expected.to validate_numericality_of(:grade_entry_item_id)
    .with_message(I18n.t('invalid_id'))
  end
  it do
    is_expected.to validate_numericality_of(:grade_entry_student_id)
    .with_message(I18n.t('invalid_id'))
  end

  it { should belong_to(:grade_entry_item) }
  it { should belong_to(:grade_entry_student) }

  it { should allow_value(0.0).for(:grade) }
  it { should allow_value(1.5).for(:grade) }
  it { should allow_value(100.0).for(:grade) }
  it { should_not allow_value(-0.5).for(:grade) }
  it { should_not allow_value(-1.0).for(:grade) }
  it { should_not allow_value(-100.0).for(:grade) }

  it { should allow_value(1).for(:grade_entry_item_id) }
  it { should allow_value(2).for(:grade_entry_item_id) }
  it { should allow_value(100).for(:grade_entry_item_id) }
  it { should_not allow_value(0).for(:grade_entry_item_id) }
  it { should_not allow_value(-1).for(:grade_entry_item_id) }
  it { should_not allow_value(-100).for(:grade_entry_item_id) }

  it { should allow_value(1).for(:grade_entry_student_id) }
  it { should allow_value(2).for(:grade_entry_student_id) }
  it { should allow_value(100).for(:grade_entry_student_id) }
  it { should_not allow_value(0).for(:grade_entry_student_id) }
  it { should_not allow_value(-1).for(:grade_entry_student_id) }
  it { should_not allow_value(-100).for(:grade_entry_student_id) }

end
