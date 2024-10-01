describe Assessment do
  it { is_expected.not_to allow_value('Mike Ooh').for(:short_identifier) }
  it { is_expected.not_to allow_value('A!a.sa').for(:short_identifier) }

  it { is_expected.to allow_value('Ads_-hb').for(:short_identifier) }
  it { is_expected.to allow_value('-22125-k1lj42_').for(:short_identifier) }
  it { is_expected.to belong_to(:course) }

  it 'throws error when short_identifier fails format validation' do
    assessment = Assessment.new(
      course: create(:course),
      description: 'mock description',
      is_hidden: false,
      short_identifier: 'Invalid@!'
    )

    expect(assessment).not_to be_valid
    error_key = 'activerecord.errors.models.assessment.attributes.short_identifier.invalid'
    expected_error = I18n.t(error_key, attribute: 'Short identifier')
    expect(assessment.errors[:short_identifier]).to include(expected_error)
  end
end
