describe Level do
  it { is_expected.to belong_to(:criterion) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to allow_value('').for(:description) }
  it { is_expected.not_to allow_value(nil).for(:description) }
  it { is_expected.to validate_presence_of(:mark) }
  it { is_expected.to have_one(:course) }

  it { is_expected.to validate_numericality_of(:mark).is_greater_than_or_equal_to(0) }
end
