describe Human do
  it { is_expected.to have_many(:roles) }
  context 'when role created' do
    let(:student) { create :student }
    it 'has roles' do
      expect(build(:human, roles: [student])).to be_valid
    end
  end
end
