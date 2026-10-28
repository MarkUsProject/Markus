describe LtiLineItemJob do
  let(:course) { create(:course) }
  let(:assessment) { create(:assignment, course: course) }
  let!(:own_deployment) { create(:lti_deployment, course: course) }
  let!(:other_deployment) { create(:lti_deployment, course: create(:course)) }
  let(:synced) { [] }

  before do
    allow_any_instance_of(LtiLineItemJob).to receive(:create_or_update_lti_assessment) do |_job, deployment, _|
      synced << deployment
    end
  end

  it 'syncs deployments in the assessment course and skips the rest' do
    LtiLineItemJob.perform_now([own_deployment.id, other_deployment.id], assessment)
    expect(synced).to contain_exactly(own_deployment)
  end
end
