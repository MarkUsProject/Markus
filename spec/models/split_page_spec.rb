describe SplitPage do
  subject { create(:split_page) }

  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'
end
