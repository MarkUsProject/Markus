describe Lti do
  context 'relationships' do
    it { is_expected.to have_one(:course) }
  end
end
