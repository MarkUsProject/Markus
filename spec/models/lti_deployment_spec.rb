describe LtiDeployment do
  context 'relationships' do
    it { is_expected.to belong_to(:course).optional }
  end
  context '#get_students' do
    let(:student) { create :student }
    let(:student_user_name) { student.user_name }
    let(:student_first_name) { student.first_name }
    let(:student_last_name) { student.last_name }
    let(:lti_service) { create :lti_service }
    let(:pub_jwk_key) { OpenSSL::PKey::RSA.new File.read(Settings.lti.key_path) }
    let(:jwk) { { keys: [JWT::JWK.new(pub_jwk_key).export] } }
    let(:scope) { 'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly' }
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
      stub_request(:get, lti_service.url).with(headers: { Authorization: 'Bearer access_token' },
                                               query: {
                                                 role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'
                                               })
                                         .to_return(status: :success, body: {
                                           id: 'http://test.host/api/lti/courses/1/names_and_roles?role=Learner',
                                           context: { id: '4dde05e8ca1973bcca9bffc13e1548820eee93a3',
                                                      label: 'tst1', title: 'test course' },
                                           members: [{ status: 'Active', name: student_user_name,
                                                       picture: 'http://example.com/picture.png',
                                                       given_name: student_first_name,
                                                       family_name: student_last_name,
                                                       lis_person_sourcedid: student_user_name,
                                                       user_id: 'lti_user_id',
                                                       lti11_legacy_user_id: 'legacy_lti_user_id',
                                                       roles:
                                                         [
                                                           'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'
                                                         ] }]
                                         }.to_json)
    end
    it 'creates an lti user' do
      lti_service.lti_deployment.get_students
      expect(LtiUser.first.user).to eq(student.user)
    end
    it 'saves the lti id correctly' do
      lti_service.lti_deployment.get_students
      expect(LtiUser.first.lti_user_id).to eq('lti_user_id')
    end
    context 'with students who are not users on markus' do
      let(:student_user_name) { 'lti_student' }
      it 'creates a new user' do
        lti_service.lti_deployment.get_students
        expect(User.count).to eq(2)
      end
      it 'creates a new role' do
        lti_service.lti_deployment.get_students
        expect(Role.count).to eq(2)
      end
      it 'creates a new role with the course' do
        expect(Role.first.course).to eq(lti_service.lti_deployment.course)
      end
    end
    context 'when there is no lti_service' do
      let(:lti_deployment) { create :lti_deployment }
      it 'fails with an error' do
        expect { lti_deployment.get_students }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
