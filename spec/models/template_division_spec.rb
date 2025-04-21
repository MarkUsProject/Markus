describe TemplateDivision do
  subject { create(:template_division) }

  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'
end
