describe LtiDeploymentsController do
  let(:instructor) { create :instructor }
  let(:target_link_uri) { 'https://example.com/authorize_redirect' }
  before { allow(File).to receive(:read).with(LtiClient::KEY_PATH).and_return(OpenSSL::PKey::RSA.new(2048)) }

  describe '#choose_course' do
    let!(:course) { create :course }
    let(:instructor) { create :instructor, course: course }
    let!(:lti) { create :lti_deployment }

    describe 'get' do
      it 'is inaccessible unless logged in' do
        get :choose_course, params: { id: lti.id }
        expect(response.status).to eq(302)
      end
      it 'is accessible when logged in' do
        session[:lti_deployment_id] = lti.id
        get_as instructor, :choose_course, params: { id: lti.id }
        expect(response.status).to eq(200)
      end
    end
    describe 'post' do
      before :each do
        session[:lti_deployment_id] = lti.id
      end
      context 'when picking a course' do
        it 'redirects to a course on success' do
          post_as instructor, :choose_course, params: { id: lti.id, course: course.id }
          expect(response).to redirect_to course_path(course)
        end
        it 'updates the course on the lti object' do
          post_as instructor, :choose_course, params: { id: lti.id, course: course.id }
          lti.reload
          expect(lti.course).to eq(course)
        end
        context 'when the user does not have permission to link' do
          let(:course2) { create :course }
          let(:instructor2) { create :instructor, course: course2 }
          it 'does not allow users to link courses they are not instructors for' do
            post_as instructor2, :choose_course, params: { id: lti.id, course: course.id }
            post_as instructor2, :choose_course, params: { id: lti.id, course: course.id }
            expect(flash[:error]).not_to be_empty
          end
        end
      end
    end
  end
  describe '#new_course' do
    let!(:lti_deployment) { create :lti_deployment }
    let(:course_params) { { id: lti_deployment.id, display_name: 'Introduction to Computer Science', name: 'csc108' } }
    before :each do
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
  describe '#public_jwk' do
    it 'responds with success when logged out' do
      get :public_jwk
      is_expected.to respond_with(:success)
    end
    it 'responds with success when logged in' do
      get_as instructor, :public_jwk
      is_expected.to respond_with(:success)
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
  describe '#create_lti_grades' do
    let!(:course) { create :course }
    let(:instructor) { create :instructor, course: course }
    let!(:lti) { create :lti_deployment, course: course }
    let(:assignment) { create :assignment_with_criteria_and_results }
    let(:scope) { LtiDeployment::LTI_SCOPES['names_role'] }
    let!(:lti_service_lineitem) { create :lti_service_lineitem, lti_deployment: lti }
    let(:lti_service_namesrole) { create :lti_service_namesrole, lti_deployment: lti }
    let(:status) { 'Active' }
    before :each do
      Result.joins(grouping: :assignment)
            .where('assignment.id': assignment.id).update!(released_to_students: true)
      User.all.each { |usr| create :lti_user, user: usr, lti_client: lti.lti_client }
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
      stub_request(:get, lti_service_namesrole.url).with(headers: { Authorization: 'Bearer access_token' },
                                                         query: {
                                                           role: LtiDeployment::LTI_ROLES[:learner]
                                                         })
                                                   .to_return(status: :success, body: {
                                                     id: 'http://test.host/api/lti/courses/1/names_and_roles?role=Learner',
                                                     context: { id: '4dde05e8ca1973bcca9bffc13e1548820eee93a3',
                                                                label: 'tst1', title: 'test course' },
                                                     members: [{ status: status, name: Student.first.display_name,
                                                                 picture: 'http://example.com/picture.png',
                                                                 given_name: Student.first.first_name,
                                                                 family_name: Student.first.last_name,
                                                                 lis_person_sourcedid: Student.first.user_name,
                                                                 email: Student.first.email,
                                                                 user_id: 'lti_user_id',
                                                                 lti11_legacy_user_id: 'legacy_lti_user_id',
                                                                 roles:
                                                                   [
                                                                     LtiDeployment::LTI_ROLES[:learner]
                                                                   ] }]
                                                   }.to_json)
      stub_request(:post, "#{lti_service_lineitem.url}/1/scores").with(headers:
                                                                             { Authorization: 'Bearer access_token' },
                                                                       body: hash_including({
                                                                         scoreGiven: /\d+(\.\d+)?/,
                                                                         scoreMaximum: assignment.max_mark.to_s,
                                                                         activityProgress: 'Completed',
                                                                         gradingProgress: 'FullyGraded'
                                                                       })).to_return(status: :success)
      stub_request(:post, lti_service_lineitem.url)
        .with(
          body: hash_including(
            { label: assignment.description,
              resourceId: assignment.short_identifier,
              scoreMaximum: assignment.max_mark.to_f.to_s }
          ),
          headers: {
            Accept: '*/*',
            'Accept-Encoding': 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            Authorization: 'Bearer access_token',
            'Content-Type': 'application/x-www-form-urlencoded',
            Host: URI(lti_service_lineitem.url).host,
            'User-Agent': 'Ruby'
          }
        ).to_return(status: :success, body: { id: "#{lti_service_lineitem.url}/1" }.to_json)
    end
    it 'redirects if not logged in' do
      post :create_lti_grades, params: { lti_deployments: [lti.id], assessment_id: assignment.id }
      expect(response.status).to eq(302)
    end
    it 'returns successfully when logged in' do
      post_as instructor, :create_lti_grades, params: { lti_deployments: [lti.id], assessment_id: assignment.id }
      expect(response.status).to eq(204)
    end
    it 'updates lti user name for a student' do
      post_as instructor, :create_lti_grades, params: { lti_deployments: [lti.id], assessment_id: assignment.id }
      expect(LtiUser.find_by(user: Student.first.user, lti_client: lti.lti_client).lti_user_id).to eq('lti_user_id')
    end
  end
end
