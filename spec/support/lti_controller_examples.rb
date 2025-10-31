shared_examples 'lti deployment controller' do
  let(:instructor) { create(:instructor) }
  let!(:client_id) { 'LMS defined ID' }
  let(:target_link_uri) { 'https://example.com/authorize_redirect' }
  let(:host) { 'https://test.host' }
  let(:state) { 'state_param' }
  let(:launch_params) do
    { client_id: 'LMS defined ID',
      login_hint: 'another opque string',
      lti_message_hint: 'opaque string',
      prompt: 'none',
      redirect_uri: 'https://example.com/authorize_redirect',
      response_mode: 'form_post',
      response_type: 'id_token',
      scope: 'openid' }
  end
  let(:redirect_uri) do
    root_uri = URI(root_url)
    root_uri.query = launch_params.to_query
    root_uri.to_s
  end
  let(:mock_roles) { [LtiDeployment::LTI_ROLES[:instructor]] }

  def create_pub_jwk
    @create_pub_jwk ||= JWT::JWK.new(OpenSSL::PKey::RSA.new(1024))
  end

  def generate_payload(roles, nonce)
    { aud: client_id,
      iss: host,
      nonce: nonce,
      LtiDeployment::LTI_CLAIMS[:deployment_id] => 'some_deployment_id',
      LtiDeployment::LTI_CLAIMS[:context] => { label: 'csc108', title: 'test' },
      LtiDeployment::LTI_CLAIMS[:custom] => { course_id: 1, user_id: 1 },
      LtiDeployment::LTI_CLAIMS[:user_id] => 'some_user_id',
      LtiDeployment::LTI_CLAIMS[:roles] => roles }
  end

  def generate_lti_jwt(roles, nonce)
    payload = generate_payload(roles, nonce)
    pub_jwk = create_pub_jwk
    JWT.encode(payload, pub_jwk.keypair, 'RS256', { kid: pub_jwk.kid })
  end

  describe '#launch' do
    context 'when launching with invalid parameters' do
      let(:lti_message_hint) { 'opaque string' }
      let(:login_hint) { 'another opque string' }

      it 'responds with unprocessable_entity if no parameters are passed' do
        request.headers['Referer'] = host
        post :launch, params: {}
        expect(subject).to respond_with(:unprocessable_content)
      end

      it 'responds with unprocessable_entity if lti_message_hint is not passed' do
        request.headers['Referer'] = host
        post :launch, params: { client_id: client_id, target_link_uri: target_link_uri, login_hint: login_hint }
        expect(subject).to respond_with(:unprocessable_content)
      end

      it 'responds with unprocessable_entity if client_id is not passed' do
        request.headers['Referer'] = host
        post :launch,
             params: { lti_message_hint: lti_message_hint, target_link_uri: target_link_uri, login_hint: login_hint }
        expect(subject).to respond_with(:unprocessable_content)
      end

      it 'responds with unprocessable_entity if target_link_uri is not passed' do
        request.headers['Referer'] = host
        post :launch, params: { lti_message_hint: lti_message_hint, client_id: client_id, login_hint: login_hint }
        expect(subject).to respond_with(:unprocessable_content)
      end

      it 'responds with unprocessable_entity if login_hint is not passed' do
        request.headers['Referer'] = host
        post :launch,
             params: { lti_message_hint: lti_message_hint, client_id: client_id, target_link_uri: target_link_uri }
        expect(subject).to respond_with(:unprocessable_content)
      end

      context 'when all required params exist' do
        before do
          stub_request(:post, "https://test.host:443#{self.described_class::LMS_REDIRECT_ENDPOINT}")
            .with(
              body: hash_including(launch_params),
              headers: {
                'Accept' => '*/*',
                'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'Content-Type' => 'application/x-www-form-urlencoded',
                'Host' => 'test.host',
                'User-Agent' => 'Ruby'
              }
            )
            .to_return(status: 302, body: 'stubbed response', headers: { location: redirect_uri })
        end

        context 'with correct parameters' do
          it 'redirects to the host auth url' do
            request.headers['Referer'] = host
            post :launch, params: { lti_message_hint: lti_message_hint,
                                    login_hint: login_hint,
                                    client_id: 'LMS defined ID', target_link_uri: target_link_uri }
            expect(response).to have_http_status(:found)
          end

          it 'sets the lti_launch cookie' do
            request.headers['Referer'] = host
            post :launch, params: { lti_message_hint: lti_message_hint,
                                    login_hint: login_hint,
                                    client_id: 'LMS defined ID', target_link_uri: target_link_uri }
            expect(cookies.encrypted[:lti_launch_data]).not_to be_nil
          end
        end
      end
    end
  end

  describe '#redirect_login' do
    let(:jwk_url) { "https://test.host:443#{self.class.described_class::LMS_JWK_ENDPOINT}" }
    let(:nonce) { rand(10 ** 30).to_s.rjust(30, '0') }

    before do
      stub_request(:get, jwk_url).to_return(status: 200, body: { keys: [create_pub_jwk.export] }.to_json)

      lti_launch_data = {}
      lti_launch_data[:client_id] = client_id
      lti_launch_data[:iss] = host
      lti_launch_data[:nonce] = nonce
      lti_launch_data[:state] = session.id
      cookies.permanent.encrypted[:lti_launch_data] =
        { value: JSON.generate(lti_launch_data), expires: 1.hour.from_now }
    end

    it 'deletes the lti_launch_cookie' do
      request.headers['Referer'] = host
      post :redirect_login, params: {}
      expect(response.cookies).to include('lti_launch_data' => nil)
    end

    context 'post' do
      context 'with incorrect or missing parameters' do
        it 'redirects to an error page with no params' do
          request.headers['Referer'] = host
          post :redirect_login, params: {}
          expect(subject).to render_template('shared/http_status')
        end

        it 'redirects to an error page with a mismatched state' do
          request.headers['Referer'] = host
          post :redirect_login, params: { state: state, id_token: 'token' }
          expect(subject).to render_template('shared/http_status')
        end
      end

      context 'with correct parameters' do
        let(:lti_jwt) { generate_lti_jwt(mock_roles, nonce) }

        before do
          session[:client_id] = client_id
        end

        it 'successfully decodes the jwt and redirects' do
          request.headers['Referer'] = host
          post_as instructor, :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
          expect(response).to redirect_to(choose_course_lti_deployment_path(LtiDeployment.first))
        end

        it 'successfully decodes the jwt and sets lti_course_id in the session' do
          request.headers['Referer'] = host
          post_as instructor, :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
          expect(LtiDeployment.first.lms_course_id).to eq(1)
        end

        it 'successfully decodes the jwt and sets lti_course_name in the session' do
          request.headers['Referer'] = host
          post_as instructor, :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
          expect(LtiDeployment.first.lms_course_name).to eq('test')
        end

        it 'successfully decodes the jwt and sets lti_course_label in the session' do
          request.headers['Referer'] = host
          post_as instructor, :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
          expect(session[:lti_course_label]).to eq('csc108')
        end

        it 'successfully decodes the jwt and sets lti_user_id in the session' do
          request.headers['Referer'] = host
          post_as instructor, :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
          expect(LtiUser.count).to eq(1)
        end

        it 'successfully creates a new lti object' do
          request.headers['Referer'] = host
          post_as instructor, :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
          expect(LtiDeployment.count).to eq(1)
        end
      end
    end

    context 'with LTI role authorization' do
      let(:admin_lti_uri) { LtiDeployment::LTI_ROLES[:admin] }
      let(:student_lti_uri) { LtiDeployment::LTI_ROLES[:learner] }
      let(:ta_lti_uri) { LtiDeployment::LTI_ROLES[:ta] }
      let(:instructor_lti_uri) { LtiDeployment::LTI_ROLES[:instructor] }

      context 'when LTI role is Instructor' do
        let(:lti_jwt) { generate_lti_jwt([instructor_lti_uri], nonce) }

        it 'redirects to course chooser' do
          request.headers['Referer'] = host
          post_as instructor, :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
          expect(response).to redirect_to(choose_course_lti_deployment_path(LtiDeployment.first))
        end
      end

      context 'when LTI role is Admin' do
        let(:lti_jwt) { generate_lti_jwt([admin_lti_uri], nonce) }

        it 'redirects to course chooser' do
          request.headers['Referer'] = host
          post_as instructor, :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
          expect(response).to redirect_to(choose_course_lti_deployment_path(LtiDeployment.first))
        end
      end

      context 'when LTI role is Student' do
        let(:lti_jwt) { generate_lti_jwt([student_lti_uri], nonce) }

        it 'redirects to "not set up" page' do
          request.headers['Referer'] = host
          post_as instructor, :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
          expect(response).to redirect_to(course_not_set_up_lti_deployment_path(LtiDeployment.first))
        end
      end

      context 'when LTI role is TA (even with Instructor claim)' do
        let(:lti_jwt) { generate_lti_jwt([ta_lti_uri, instructor_lti_uri], nonce) }

        it 'redirects to "not set up" page' do
          request.headers['Referer'] = host
          post_as instructor, :redirect_login, params: { state: session.id.to_s, id_token: lti_jwt }
          expect(response).to redirect_to(course_not_set_up_lti_deployment_path(LtiDeployment.first))
        end
      end
    end

    context 'get' do
      it 'returns an error if not logged in' do
        request.headers['Referer'] = host
        get :redirect_login
        expect(subject).to render_template('shared/http_status')
      end

      it 'returns an error if cookie is not present' do
        request.headers['Referer'] = host
        get_as instructor, :redirect_login
        expect(subject).to render_template('shared/http_status')
      end
    end

    context 'with a cookie' do
      let(:lti_data) do
        { host: 'example.com',
          client_id: 'client_id',
          deployment_id: '28:f97330a96452fc363a34e0ef6d8d0d3e9e1007d2',
          lms_course_name: 'Introduction to Computer Science',
          lms_course_label: 'CSC108',
          lms_course_id: 1,
          lti_user_id: 'user_id',
          user_roles: mock_roles }
      end
      let(:payload) do
        { aud: client_id,
          iss: 'https://example.com',
          LtiDeployment::LTI_CLAIMS[:deployment_id] => 'some_deployment_id',
          LtiDeployment::LTI_CLAIMS[:context] => {
            label: 'csc108',
            title: 'test'
          },
          LtiDeployment::LTI_CLAIMS[:custom] => {
            course_id: 1,
            user_id: 1
          },
          LtiDeployment::LTI_CLAIMS[:roles] => mock_roles }
      end

      before do
        cookies.permanent.encrypted[:lti_data] = { value: JSON.generate(lti_data), expires: 5.minutes.from_now }
      end

      it 'successfully decodes the jwt and redirects' do
        request.headers['Referer'] = host
        get_as instructor, :redirect_login
        expect(response).to redirect_to(choose_course_lti_deployment_path(LtiDeployment.first))
      end

      it 'successfully decodes the jwt and sets lti_course_id in the session' do
        request.headers['Referer'] = host
        get_as instructor, :redirect_login
        expect(LtiDeployment.first.lms_course_id).to eq(1)
      end

      it 'successfully decodes the jwt and sets lti_course_name in the session' do
        request.headers['Referer'] = host
        get_as instructor, :redirect_login
        expect(LtiDeployment.first.lms_course_name).to eq('Introduction to Computer Science')
      end

      it 'successfully decodes the jwt and sets lti_course_label in the session' do
        request.headers['Referer'] = host
        get_as instructor, :redirect_login
        expect(session[:lti_course_label]).to eq('CSC108')
      end

      it 'successfully decodes the jwt and sets lti_user_id in the session' do
        request.headers['Referer'] = host
        get_as instructor, :redirect_login
        expect(LtiUser.count).to eq(1)
      end

      it 'successfully creates a new lti object' do
        request.headers['Referer'] = host
        get_as instructor, :redirect_login
        expect(LtiDeployment.count).to eq(1)
      end

      it 'deletes the data cookie' do
        request.headers['Referer'] = host
        get_as instructor, :redirect_login
        expect(response.cookies).to include('lti_data' => nil)
      end
    end
  end

  describe '#check_host' do
    before do
      request.env['HTTP_REFERER'] = root_url
    end

    it 'does not redirect to an error with a known host' do
      get_as instructor, :redirect_login
      expect(subject).to respond_with(:success)
    end

    it 'does redirect to an error with an unknown host' do
      request.headers['Referer'] = 'http://example.com'
      post_as instructor, :launch, params: { lti_message_hint: 'hint',
                                             login_hint: 'hint',
                                             client_id: 'LMS defined ID', target_link_uri: 'test.com' }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
