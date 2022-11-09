shared_examples 'lti deployment controller' do
  let(:instructor) { create :instructor }
  let!(:client_id) { 'LMS defined ID' }
  let(:target_link_uri) { 'https://example.com/authorize_redirect' }
  let(:host) { 'https://canvas.instructure.com' }
  let(:state) { 'state_param' }
  describe '#launch' do
    context 'when launching with invalid parameters' do
      let(:lti_message_hint) { 'opaque string' }
      let(:login_hint) { 'another opque string' }
      let(:auth_url) { 'http://canvas.instructure.com:433/api/lti/authorize_redirect' }
      it 'responds with unprocessable_entity if no parameters are passed' do
        post :launch, params: {}
        is_expected.to respond_with(:unprocessable_entity)
      end
      it 'responds with unprocessable_entity if lti_message_hint is not passed' do
        post :launch, params: { client_id: client_id, target_link_uri: target_link_uri, login_hint: login_hint }
        is_expected.to respond_with(:unprocessable_entity)
      end
      it 'responds with unprocessable_entity if client_id is not passed' do
        post :launch,
             params: { lti_message_hint: lti_message_hint, target_link_uri: target_link_uri, login_hint: login_hint }
        is_expected.to respond_with(:unprocessable_entity)
      end
      it 'responds with unprocessable_entity if target_link_uri is not passed' do
        post :launch, params: { lti_message_hint: lti_message_hint, client_id: client_id, login_hint: login_hint }
        is_expected.to respond_with(:unprocessable_entity)
      end
      it 'responds with unprocessable_entity if login_hint is not passed' do
        post :launch,
             params: { lti_message_hint: lti_message_hint, client_id: client_id, target_link_uri: target_link_uri }
        is_expected.to respond_with(:unprocessable_entity)
      end
      context 'when all required params exist' do
        before :each do
          stub_request(:post, 'http://canvas.instructure.com:443/api/lti/authorize_redirect')
            .with(
              body: hash_including({ client_id: 'LMS defined ID',
                                     login_hint: 'another opque string',
                                     lti_message_hint: 'opaque string',
                                     prompt: 'none',
                                     redirect_uri: 'https://example.com/authorize_redirect',
                                     response_mode: 'form_post',
                                     response_type: 'id_token',
                                     scope: 'openid' }),
              headers: {
                Accept: '*/*'
              }
            )
            .to_return(status: 302, body: 'stubbed response', headers: { location: root_url })
        end
        context 'with correct parameters' do
          before { controller.request.headers.merge(HTTP_REFERER: host) }
          it 'redirects to the host auth url' do
            post :launch, params: { lti_message_hint: lti_message_hint,
                                    login_hint: login_hint,
                                    client_id: client_id, target_link_uri: target_link_uri }
            expect(response).to redirect_to(root_url)
          end
        end
      end
    end
  end
  describe '#redirect_login' do
    before :each do
      controller.request.headers.merge(HTTP_REFERER: host)
    end
    context 'with incorrect or missing parameters' do
      it 'redirects to an error page with no params' do
        post :redirect_login, params: {}
        is_expected.to render_template('shared/http_status')
      end
      it 'redirects to an error page with a mismatched state' do
        post :redirect_login, params: { state: state, id_token: 'token' }
        is_expected.to render_template('shared/http_status')
      end
    end
    context 'with correct parameters' do
      let(:jwk_url) { 'https://canvas.instructure.com:443/api/lti/security/jwks' }
      let(:payload) do
        { aud: client_id,
          iss: 'https://canvas.instructure.com',
          'https://purl.imsglobal.org/spec/lti/claim/deployment_id': 'some_deployment_id',
          'https://purl.imsglobal.org/spec/lti/claim/context': {
            label: 'csc108',
            title: 'test'
          },
          'https://purl.imsglobal.org/spec/lti/claim/custom': {
            course_id: 1,
            user_id: 1
          } }
      end
      let(:pub_jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.new(1024)) }
      let(:lti_jwt) { JWT.encode(payload, pub_jwk.keypair, 'RS256', { kid: pub_jwk.kid }) }
      before :each do
        session[:client_id] = client_id
        stub_request(:get, jwk_url).to_return(status: 200, body: { keys: [pub_jwk.export] }.to_json)
      end
      it 'successfully decodes the jwt and redirects' do
        post :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
        expect(response).to redirect_to(root_path)
      end
      it 'successfully decodes the jwt and sets lti_course_id in the session' do
        post :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
        expect(session[:lti_course_id]).to eq(1)
      end
      it 'successfully decodes the jwt and sets lti_course_name in the session' do
        post :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
        expect(session[:lti_course_name]).to eq('test')
      end
      it 'successfully decodes the jwt and sets lti_course_label in the session' do
        post :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
        expect(session[:lti_course_label]).to eq('csc108')
      end
      it 'successfully decodes the jwt and sets lti_user_id in the session' do
        post :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
        expect(session[:lti_user_id]).to eq(1)
      end
      it 'successfully creates a new lti object' do
        post :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
        expect(LtiDeployment.count).to eq(1)
      end
    end
  end
  describe '#check_host' do
    it 'does not redirect to an error with a known host' do
      get_as instructor, :get_config
      is_expected.to respond_with(:success)
    end
    it 'does redirect to an error with an unknown host' do
      @request.host = 'example.com'
      get_as instructor, :get_config
      expect(response.status).to eq(422)
    end
  end
end
