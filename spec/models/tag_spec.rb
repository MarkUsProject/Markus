describe Tag do
  subject { create(:tag, assessment: create(:assignment)) }
  it { is_expected.to have_one(:course) }
  include_examples 'course associations'
end
