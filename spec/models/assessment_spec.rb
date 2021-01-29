describe Assessment do
  it { is_expected.to allow_value('s-1_3j').for(:short_identifier) }
  it { is_expected.to allow_value('-_-').for(:short_identifier) }
  it { is_expected.to_not allow_value('s~1').for(:short_identifier) }
  it { is_expected.to_not allow_value('s 11').for(:short_identifier) }
end
