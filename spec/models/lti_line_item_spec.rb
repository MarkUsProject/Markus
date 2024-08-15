describe LtiLineItem do
  subject { create(:lti_line_item, assessment: assessment, lti_deployment: lti_deployment) }

  let(:assessment) { create(:assignment) }
  let(:lti_deployment) { create(:lti_deployment) }

  it { is_expected.to belong_to(:lti_deployment) }
  it { is_expected.to belong_to(:assessment) }
  it { is_expected.to validate_uniqueness_of(:assessment).scoped_to(:lti_deployment_id) }
end
