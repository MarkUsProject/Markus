describe Assessment do
  it { is_expected.not_to allow_value('Mike Ooh').for(:short_identifier) }
  it { is_expected.not_to allow_value('A!a.sa').for(:short_identifier) }

  it { is_expected.to allow_value('Ads_-hb').for(:short_identifier) }
  it { is_expected.to allow_value('-22125-k1lj42_').for(:short_identifier) }
  it { is_expected.to belong_to(:course) }
end
