describe TestBatch do
  it { is_expected.to have_many(:test_runs) }
  it { is_expected.to belong_to(:course) }
end
