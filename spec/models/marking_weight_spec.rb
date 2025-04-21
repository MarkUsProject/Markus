describe MarkingWeight do
  subject { create(:marking_weight) }

  it { is_expected.to belong_to(:marking_scheme) }
  it { is_expected.to belong_to(:assessment) }
  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'
end
