describe LtiDeployment do
  context 'relationships' do
    it { is_expected.to belong_to(:course).optional }
  end
end
