describe LtiDeploymentsController do
  let(:instructor) { create(:instructor) }
  let(:admin_user) { create(:admin_user) }
  let(:target_link_uri) { 'https://example.com/authorize_redirect' }

  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(LtiClient::KEY_PATH).and_return(OpenSSL::PKey::RSA.new(2048))
  end

  describe '#choose_course' do
    let!(:course) { create(:course) }
    let(:instructor) { create(:instructor, course: course) }
    let!(:lti) { create(:lti_deployment) }

    describe 'get' do
      it 'is inaccessible unless logged in' do
        get :choose_course, params: { id: lti.id }
        expect(response).to have_http_status(:found)
      end

      it 'is accessible when logged in' do
        session[:lti_deployment_id] = lti.id
        get_as instructor, :choose_course, params: { id: lti.id }
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'post' do
      before do
        session[:lti_deployment_id] = lti.id
      end

      context 'when picking a course' do
        it 'redirects to a course on success' do
          post_as instructor, :choose_course, params: { id: lti.id, course: course.id }
          expect(response).to redirect_to course_path(course)
        end

        it 'redirects to a course for an admin' do
          post_as admin_user, :choose_course, params: { id: lti.id, course: course.id }
          expect(response).to redirect_to course_path(course)
        end

        it 'updates the course on the lti object' do
          post_as instructor, :choose_course, params: { id: lti.id, course: course.id }
          lti.reload
          expect(lti.course).to eq(course)
        end

        context 'when the user does not have permission to link' do
          let(:course2) { create(:course) }
          let(:instructor2) { create(:instructor, course: course2) }

          it 'does not allow users to link courses they are not instructors for' do
            post_as instructor2, :choose_course, params: { id: lti.id, course: course.id }
            post_as instructor2, :choose_course, params: { id: lti.id, course: course.id }
            expect(flash[:error]).not_to be_empty
          end
        end
      end
    end
  end

  describe '#create_course' do
    let!(:lti_deployment) { create(:lti_deployment, lms_course_name: 'csc108') }
    let(:course_params) do
      { id: lti_deployment.id, display_name: 'Introduction to Computer Science', name: lti_deployment.lms_course_name }
    end

    context 'as an instructor' do
      before do
        session[:lti_deployment_id] = lti_deployment.id
        post_as instructor, :create_course, params: course_params
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

    context 'as an admin user' do
      before do
        session[:lti_deployment_id] = lti_deployment.id
        post_as admin_user, :create_course, params: course_params
      end

      it 'creates a course' do
        expect(Course.find_by(name: 'csc108')).not_to be_nil
      end

      it 'sets the course display name' do
        expect(Course.find_by(display_name: 'Introduction to Computer Science')).not_to be_nil
      end

      it 'creates an admin role for the user' do
        expect(Role.find_by(user: admin_user, course: Course.find_by(name: 'csc108'), type: 'AdminRole')).not_to be_nil
      end
    end

    context 'when a course already exists' do
      before do
        create(:course, display_name: 'Introduction to Computer Science', name: lti_deployment.lms_course_name)
        session[:lti_deployment_id] = lti_deployment.id
      end

      it 'does not create a new course' do
        post_as instructor, :create_course, params: course_params
        expect(Course.count).to eq(1)
      end

      it 'does redirect to choose_course' do
        post_as instructor, :create_course, params: course_params
        expect(response).to have_http_status(:found)
      end
    end

    context 'when the LTI deployment course name has invalid characters' do
      let!(:lti_deployment) { create(:lti_deployment, lms_course_name: 'csc108 fall 3000!') }

      before do
        session[:lti_deployment_id] = lti_deployment.id
      end

      it 'creates a new course with a sanitized name' do
        post_as instructor, :create_course, params: course_params
        expect(Course.exists?(name: 'csc108-fall-3000-')).not_to be_nil
      end
    end

    context 'when the course is rejected by the filter' do
      # NOTE: the default filter in config/dummy_lti_config.rb only accepts course names starting with 'csc'
      let!(:lti_deployment) { create(:lti_deployment, lms_course_name: 'sta130') }

      before do
        session[:lti_deployment_id] = lti_deployment.id
      end

      it 'does not create a new course' do
        post_as instructor, :create_course, params: course_params
        expect(Course.count).to eq(1)
      end

      it 'responds with an error message' do
        post_as instructor, :create_course, params: course_params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#public_jwk' do
    it 'responds with success when logged out' do
      get :public_jwk
      expect(subject).to respond_with(:success)
    end

    it 'responds with success when logged in' do
      get_as instructor, :public_jwk
      expect(subject).to respond_with(:success)
    end

    it 'responds with valid JSON' do
      jwk = get :public_jwk
      expect { JSON.parse(jwk.body) }.not_to raise_error
    end

    context 'a valid jwk set' do
      let(:pub_jwk) { get :public_jwk }
      let(:hash_jwk) { JSON.parse(pub_jwk.body) }

      it 'stores keys under the key parameter' do
        expect(hash_jwk).to have_key('keys')
      end

      it 'stores keys as a list' do
        expect(hash_jwk['keys']).to be_a(Array)
      end

      context 'an individual key' do
        let(:pub_jwk) { get :public_jwk }
        let(:hash_jwk) { JSON.parse(pub_jwk.body) }
        let(:jwk_key) { hash_jwk['keys'][0] }

        it 'stores the correct signing algorithm' do
          expect(jwk_key['kty']).to eq('RSA')
        end

        it 'has a kid parameter' do
          expect(jwk_key).to have_key('kid')
        end

        it 'verifies a signed message' do
          payload = { test: 'data' }
          token = JWT.encode payload, File.read(LtiClient::KEY_PATH), 'RS256', { kid: jwk_key['kid'] }
          decoded = JWT.decode(token, nil, true, algorithms: ['RS256'], verify_iss: false, verify_aud: false,
                                                 jwks: hash_jwk)
          expect(decoded[0]['test']).to match('data')
        end
      end
    end
  end
end
