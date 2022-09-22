describe LtiLineItem do
  it { is_expected.to belong_to(:lti_deployment) }
  it { is_expected.to belong_to(:assessment) }
  it { is_expected.to validate_uniqueness_of(:assessment).scoped_to(:lti_deployment_id) }
end
