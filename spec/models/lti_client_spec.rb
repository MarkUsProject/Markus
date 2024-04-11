describe LtiClient do
  describe 'uniqueness_validation' do
    subject { create(:lti_client) }
    it { is_expected.to validate_uniqueness_of(:client_id).scoped_to(:host) }
  end
  before { allow(File).to receive(:read).with(LtiClient::KEY_PATH).and_return(OpenSSL::PKey::RSA.new(2048)) }
  describe '#get_oauth_token' do
    let(:lti_client) { create(:lti_client) }
    let(:scope) { LtiDeployment::LTI_SCOPES[:ags_lineitem] }
    before :each do
      stub_request(:post, Settings.lti.token_endpoint)
        .with(
          body: hash_including(
            { grant_type: 'client_credentials',
              client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
              scope: scope,
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
    context 'with a correct payload' do
      it 'returns a correct token' do
        expect(
          lti_client.get_oauth_token([scope])
        ).to include('access_token')
      end
      it 'returns the correct scopes' do
        expect(
          lti_client.get_oauth_token([scope])['scope']
        ).to eq(scope)
      end
      it 'returns a valid expiration time' do
        expect(
          lti_client.get_oauth_token([scope])['expires_in']
        ).to be > 0
      end
      it 'returns the correct token type' do
        expect(
          lti_client.get_oauth_token([scope])['token_type']
        ).to eq('Bearer')
      end
    end
  end
end
