describe LtiDeploymentController do
  let(:instructor) { create :instructor }
  let!(:client_id) { 'LMS defined ID' }
  let(:target_link_uri) { 'https://example.com/authorize_redirect' }
  let(:host) { 'https://canvas.instructure.com' }
  let(:state) { 'state_param' }
  describe 'get_config', :get_canvas_config do
    it 'should respond with success when not logged in' do
      is_expected.to respond_with(:success)
    end
    before { get_as instructor, :get_canvas_config }
    it 'should respond with success when logged in' do
      is_expected.to respond_with(:success)
    end
  end
  describe '#launch', :launch do
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
  describe '#choose_course', :choose_course do
    let!(:course) { create :course }
    let(:instructor) { create :instructor, course: course }
    let!(:lti) { create :lti_deployment }

    before :each do
      session[:lti_deployment_id] = lti.id
    end
    context 'when picking a course' do
      it 'redirects to a course on success' do
        post_as instructor, :choose_course, params: { course: course.id }
        expect(response).to redirect_to course_path(course)
      end
      it 'updates the course on the lti object' do
        post_as instructor, :choose_course, params: { course: course.id }
        lti.reload
        expect(lti.course).to eq(course)
      end
      context 'when the user does not have permission to link' do
        let(:course2) { create :course }
        let(:instructor2) { create :instructor, course: course2 }
        it 'does not allow users to link courses they are not instructors for' do
          post_as instructor2, :choose_course, params: { course: course.id }
          expect(flash[:error]).not_to be_empty
        end
      end
    end
  end
  describe '#check_host' do
    it 'does not redirect to an error with a known host' do
      get_as instructor, :get_canvas_config
      is_expected.to respond_with(:success)
    end
    it 'does redirect to an error with an unknown host' do
      @request.host = 'example.com'
      get_as instructor, :get_canvas_config
      expect(response).to render_template('shared/http_status')
    end
  end
  describe '#new_course' do
    let(:lti_deployment) { create :lti_deployment }
    let(:course_params) { { display_name: 'Introduction to Computer Science', name: 'csc108' } }
    before :each do
      session[:lti_deployment_id] = lti_deployment.id
      post_as instructor, :new_course, params: course_params
    end
    it 'creates a course' do
      expect(Course.find_by(name: 'csc108')).not_to be_nil
    end
    it 'sets the course display name' do
      expect(Course.find_by(display_name: 'Introduction to Computer Science')).not_to be_nil
    end
    it 'creates an instructor role for the user' do
      expect(Role.find_by(user: instructor.user, course: Course.find_by(name: 'csc108'))).not_to be_nil
    end
  end
end
