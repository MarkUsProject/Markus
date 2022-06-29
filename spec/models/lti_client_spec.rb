describe LtiClient do
  describe 'uniqueness_validation' do
    subject { create :lti_client }
    it { is_expected.to validate_uniqueness_of(:client_id).scoped_to(:host) }
  end
  describe '#get_oauth_token' do
    # let!(:lti_client) { create :lti_client }
    let(:lti_deployment) { create :lti_deployment, lti_client: lti_client }
    let(:base_url) { 'http://example.com' }
    let(:pub_jwk_key) { OpenSSL::PKey::RSA.new File.read("#{Settings.lti.key_path}/key.pem") }
    let(:jwk) { { keys: [JWT::JWK.new(pub_jwk_key).export] } }
    let(:scope) { 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem' }
    before :each do
      @lti_client = LtiClient.new(client_id: '1', host: base_url)
      stub_request(:post, Settings.lti.token_endpoint)
        .with(
          body: hash_including(
            { grant_type: 'client_credentials',
              client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
              scope: 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
              client_assertion: /.*/ }
          ),
          headers: {
            Accept: '*/*'
          }
        ).to_return(status: 200, body: { access_token: 'access_token' }.to_json)
    end
    context 'with a correct payload' do
      it 'returns a correct token' do
        # byebug
        expect(
          @lti_client.get_oauth_token(base_url, [scope])
        ).to include('access_token')
      end
    end
  end
end
