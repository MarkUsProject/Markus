describe Tag do
  subject { create(:tag, assessment: create(:assignment)) }

  it { is_expected.to have_one(:course) }

  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:assessment_id) }

  include_examples 'course associations'
end
