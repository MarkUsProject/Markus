describe LtiRosterSyncJob do
  include LtiHelper

  let(:course) { create(:course) }
  let(:lti_deployment) { create(:lti_deployment, course: course) }
  let(:scope) { LtiDeployment::LTI_SCOPES[:names_role] }
  let(:assessment) { create(:assignment_with_criteria_and_results, course: course) }

  before do
    allow(File).to receive(:read).with(LtiClient::KEY_PATH).and_return(OpenSSL::PKey::RSA.new(2048))
    stub_request(:post, Settings.lti.token_endpoint)
      .with(
        body: hash_including(
          { grant_type: 'client_credentials',
            client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
            scope: /.*/,
            client_assertion: /.*/ }
        ),
        headers: {
          Accept: '*/*'
        }
      ).to_return(status: :success, body: { access_token: 'access_token',
                                            scope: scope,
                                            token_type: 'Bearer',
                                            expires_in: 3600 }.to_json)

    create(:lti_service_namesrole, lti_deployment: lti_deployment)
    create(:student, course: course)
  end

  context 'when running as a background job' do
    let(:job_args) do
      [{ deployment_id: lti_deployment.id,
         role_types: [LtiDeployment::LTI_ROLES[:learner], LtiDeployment::LTI_ROLES[:ta]] }]
    end

    it_behaves_like 'background job'
  end
end
