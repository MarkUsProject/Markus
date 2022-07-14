describe LtiService do
  subject { create :lti_service }
  it { is_expected.to belong_to(:lti_deployment) }
  it { is_expected.to validate_uniqueness_of(:service_type).scoped_to(:lti_deployment_id) }
end
