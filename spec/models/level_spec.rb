describe Level do
  it { is_expected.to belong_to(:criterion) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to allow_value('').for(:description) }
  it { is_expected.not_to allow_value(nil).for(:description) }
  it { is_expected.to validate_presence_of(:mark) }
  it { is_expected.to have_one(:course) }

  it { is_expected.to validate_numericality_of(:mark).is_greater_than_or_equal_to(0) }

  describe 'uniqueness validations' do
    subject { create(:level, mark: 0.5) }

    it { is_expected.to validate_uniqueness_of(:mark).scoped_to(:criterion_id) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:criterion_id) }
  end
end
