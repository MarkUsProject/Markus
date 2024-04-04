describe LtiSyncJob do
  include LtiHelper
  before :each do
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
  end
  let(:course) { create(:course) }
  let(:lti_deployment) { create(:lti_deployment, course: course) }
  let(:assessment) { create(:assignment_with_criteria_and_results, course: course) }
  let!(:lti_lineitem) { create(:lti_line_item, lti_deployment: lti_deployment, assessment: assessment) }
  let(:scope) { LtiDeployment::LTI_SCOPES[:ags_lineitem] }

  context 'when running as a background job' do
    let(:job_args) { [[lti_deployment.id], assessment] }
    include_examples 'background job'
  end
end
