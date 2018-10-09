describe ExtraMark do

  context 'checks relationships' do
    it { is_expected.to belong_to(:result) }
    it { is_expected.to validate_presence_of(:unit) }
  end
end
