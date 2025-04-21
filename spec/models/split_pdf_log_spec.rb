describe SplitPdfLog do
  subject { create(:split_pdf_log) }

  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'
end
