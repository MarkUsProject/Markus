describe TemplateDivision do
  subject { create(:template_division) }

  it { is_expected.to have_one(:course) }

  include_examples 'course associations'
end
