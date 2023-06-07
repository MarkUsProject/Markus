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
  let(:course) { create :course }
  let(:lti_deployment) { create :lti_deployment, course: course }
  let!(:lti_service_namesrole) { create :lti_service_namesrole, lti_deployment: lti_deployment }
  let!(:student) { create :student, course: course }
  let(:scope) { LtiDeployment::LTI_SCOPES[:names_role] }

  context 'when running as a background job' do
    let(:job_args) do
      [[lti_deployment.id], course, [LtiDeployment::LTI_ROLES[:learner], LtiDeployment::LTI_ROLES[:ta]]]
    end
    include_examples 'background job'
  end
  context 'with no lti deployments' do
    let(:job_args) { [[], assessment, course, [LtiDeployment::LTI_ROLES[:learner], LtiDeployment::LTI_ROLES[:ta]]] }
    it 'should raise an error' do
      expect { described_class.perform_now(*job_args) }.to raise_error
    end
  end
end
