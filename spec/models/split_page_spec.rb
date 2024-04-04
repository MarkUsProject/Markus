describe SplitPage do
  subject { create(:split_page) }
  it { is_expected.to have_one(:course) }
  include_examples 'course associations'
end
