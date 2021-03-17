describe Result do
  it { is_expected.to belong_to(:submission) }
  it { is_expected.to have_many(:marks) }
  it { is_expected.to have_many(:extra_marks) }
  it { is_expected.to have_many(:annotations) }
  it { is_expected.to validate_presence_of(:marking_state) }
  it { is_expected.to validate_inclusion_of(:marking_state).in_array(['complete', 'incomplete']) }
  it { is_expected.to validate_numericality_of(:total_mark).is_greater_than_or_equal_to(0) }
  it { is_expected.to callback(:create_marks).after(:create) }
  it { is_expected.to callback(:check_for_released).before(:update) }
  it { is_expected.to callback(:check_for_nil_marks).before(:save) }

  
end
