describe LtiDeployment do
  context 'relationships' do
    it { is_expected.to belong_to(:course).optional }
  end
  before { allow(File).to receive(:read).with(LtiClient::KEY_PATH).and_return(OpenSSL::PKey::RSA.new(2048)) }
  context '#get_students' do
    let(:student) { create :student }
    let(:student_user_name) { student.user_name }
    let(:student_first_name) { student.first_name }
    let(:student_last_name) { student.last_name }
    let(:student_display_name) { student.display_name }
    let(:student_email) { student.email }
    let(:course) { create :course }
    let(:lti_deployment) { create :lti_deployment, course: course }
    let(:lti_service_namesrole) { create :lti_service_namesrole, lti_deployment: lti_deployment }
    let(:pub_jwk_key) { OpenSSL::PKey::RSA.new File.read(LtiClient::KEY_PATH) }
    let(:jwk) { { keys: [JWT::JWK.new(pub_jwk_key).export] } }
    let(:scope) { LtiDeployment::LTI_SCOPES[:names_role] }
    let(:status) { 'Active' }
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
      stub_request(:get, lti_service_namesrole.url).with(headers: { Authorization: 'Bearer access_token' },
                                                         query: {
                                                           role: LtiDeployment::LTI_ROLES[:learner]
                                                         })
                                                   .to_return(status: :success, body: {
                                                     id: 'http://test.host/api/lti/courses/1/names_and_roles?role=Learner',
                                                     context: { id: '4dde05e8ca1973bcca9bffc13e1548820eee93a3',
                                                                label: 'tst1', title: 'test course' },
                                                     members: [{ status: status, name: student_display_name,
                                                                 picture: 'http://example.com/picture.png',
                                                                 given_name: student_first_name,
                                                                 family_name: student_last_name,
                                                                 lis_person_sourcedid: student_user_name,
                                                                 email: student_email,
                                                                 user_id: 'lti_user_id',
                                                                 lti11_legacy_user_id: 'legacy_lti_user_id',
                                                                 roles:
                                                         [
                                                           LtiDeployment::LTI_ROLES[:learner]
                                                         ] },
                                                               { status: status, name: 'second user',
                                                                 picture: 'http://example.com/picture.png',
                                                                 given_name: student_first_name,
                                                                 family_name: student_last_name,
                                                                 lis_person_sourcedid: 'second_username',
                                                                 email: student_email,
                                                                 user_id: 'another_user_id',
                                                                 lti11_legacy_user_id: 'legacy_lti_user_id',
                                                                 roles:
                                                                   [
                                                                     LtiDeployment::LTI_ROLES[:learner]
                                                                   ] }]
                                                   }.to_json)
    end
    it 'creates additional users' do
      lti_service_namesrole.lti_deployment.get_students
      expect(User.count).to eq(2)
    end
    it 'creates additional roles' do
      lti_service_namesrole.lti_deployment.get_students
      expect(Role.count).to eq(2)
    end
    it 'creates lti users' do
      lti_service_namesrole.lti_deployment.get_students
      expect(LtiUser.first.user).to eq(student.user)
    end
    it 'saves the lti id correctly' do
      lti_service_namesrole.lti_deployment.get_students
      expect(LtiUser.first.lti_user_id).to eq('lti_user_id')
    end
    it 'saves a second correct lti id' do
      lti_service_namesrole.lti_deployment.get_students
      expect(LtiUser.second.lti_user_id).to eq('another_user_id')
    end
    context 'with students who are not users on markus' do
      let(:student_user_name) { 'lti_student' }
      it 'creates a new user' do
        lti_service_namesrole.lti_deployment.get_students
        expect(User.count).to eq(3)
      end
      it 'sets the correct username' do
        lti_service_namesrole.lti_deployment.get_students
        expect(User.find_by(user_name: student_user_name)).not_to be_nil
      end
      it 'sets the correct first name' do
        lti_service_namesrole.lti_deployment.get_students
        expect(User.find_by(user_name: student_user_name).first_name).to eq(student_first_name)
      end
      it 'sets the correct last name' do
        lti_service_namesrole.lti_deployment.get_students
        expect(User.find_by(user_name: student_user_name).last_name).to eq(student_last_name)
      end
      it 'sets the correct display name' do
        lti_service_namesrole.lti_deployment.get_students
        expect(User.find_by(user_name: student_user_name).display_name).to eq(student_display_name)
      end
      it 'creates a new role' do
        lti_service_namesrole.lti_deployment.get_students
        expect(Role.count).to eq(3)
      end
      it 'creates a new role with the course' do
        expect(Role.first.course).to eq(lti_service_namesrole.lti_deployment.course)
      end
    end
    context 'when the user exists but the role does not' do
      let(:new_user) { create :end_user }
      let(:student_user_name) { new_user.user_name }
      let(:student_first_name) { new_user.first_name }
      let(:student_last_name) { new_user.last_name }
      let(:student_display_name) { new_user.display_name }
      let(:student_email) { new_user.email }
      it 'creates a role for the user' do
        lti_service_namesrole.lti_deployment.get_students
        expect(Role.find_by(user: new_user).course).to eq(course)
      end
    end
    context 'when the user is inactive' do
      let(:status) { 'Inactive' }
      it 'does not create an lti_user' do
        lti_service_namesrole.lti_deployment.get_students
        expect(LtiUser.count).to eq(0)
      end
    end
    context 'when there is no lti_service_namesrole' do
      let(:second_lti_deployment) { create :lti_deployment }
      it 'fails with an error' do
        expect { second_lti_deployment.get_students }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
  describe '#create_or_update_lti_assessment' do
    let(:course) { create :course }
    let(:lti_deployment) { create :lti_deployment, course: course }
    let(:assessment) { create :assignment, course: course }
    let(:scope) { LtiDeployment::LTI_SCOPES[:ags_lineitem] }
    let(:lti_service_lineitem) { create :lti_service_lineitem, lti_deployment: lti_deployment }
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

      stub_request(:post, lti_service_lineitem.url)
        .with(
          body: hash_including(
            { label: assessment.description,
              resourceId: assessment.short_identifier,
              scoreMaximum: assessment.max_mark.to_f.to_s }
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
    it 'creates a new lti line item' do
      lti_deployment.create_or_update_lti_assessment(assessment)
      expect(LtiLineItem.count).to eq(1)
    end
    it 'sets the correct url' do
      lti_deployment.create_or_update_lti_assessment(assessment)
      expect(LtiLineItem.first.lti_line_item_id).to include(lti_service_lineitem.url)
    end
  end
  describe '#create_grades' do
    let(:course) { create :course }
    let(:student) { create :student }
    let(:lti_deployment) { create :lti_deployment, course: course }
    let!(:assessment) { create :assignment_with_criteria_and_results, course: course }

    let(:scope) { LtiDeployment::LTI_SCOPES[:score] }
    let(:lti_service_lineitem) { create :lti_service_lineitem, lti_deployment: lti_deployment }
    let(:lti_line_item) { create :lti_line_item, assessment: assessment, lti_deployment: lti_deployment }
    let(:lti_service_namesrole) { create :lti_service_namesrole, lti_deployment: lti_deployment }
    let(:status) { 'Active' }
    before :each do
      Result.joins(grouping: :assignment)
            .where('assignment.id': assessment.id).update!(released_to_students: true)
      User.all.each { |usr| create :lti_user, user: usr, lti_client: lti_deployment.lti_client }
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
      stub_request(:post, "#{lti_line_item.lti_line_item_id}/scores").with(headers:
                                                                            { Authorization: 'Bearer access_token' },
                                                                           body: hash_including({
                                                                             scoreGiven: /\d+(\.\d+)?/,
                                                                             scoreMaximum: assessment.max_mark.to_s,
                                                                             activityProgress: 'Completed',
                                                                             gradingProgress: 'FullyGraded'
                                                                           })).to_return(status: :success)
    end
    it 'does send grades' do
      expect(lti_deployment.create_grades(assessment)).not_to be_empty
    end
  end
  describe '#get_assignment_grades' do
    let(:course) { create :course }
    let(:student1) { create :student, course: course }
    let(:lti_deployment) { create :lti_deployment, course: course }
    let!(:assessment) { create :assignment_with_criteria_and_results, course: course }
    let!(:assessment2) { create :assignment_with_criteria_and_results, course: course }
    before :each do
      User.all.each do |usr|
        create :lti_user, user: usr, lti_client: lti_deployment.lti_client if LtiUser.find_by(user: usr).nil?
      end
      Result.joins(grouping: :assignment)
            .where('assignment.id': assessment.id).update!(released_to_students: true)
    end
    it 'successfully gets grades for an assignment with released grades' do
      expect(lti_deployment.get_assignment_marks(assessment)).not_to be_empty
    end
    it 'does not get unreleased grades' do
      expect(lti_deployment.get_assignment_marks(assessment2)).to be_empty
    end
    it 'does not get unreleased grades for an assignment with released grades' do
      Result.joins(grouping: :assignment)
            .where('assignment.id': assessment2.id).first.update!(released_to_students: true)
      expect(lti_deployment.get_assignment_marks(assessment2)).not_to be_empty
    end
  end
  describe '#get_grade_entry_form_marks' do
    let(:course) { create :course }
    let!(:student1) { create :student, course: course }
    let(:lti_deployment) { create :lti_deployment, course: course }
    let!(:assessment) { create :grade_entry_form_with_data, course: course }
    before :each do
      User.all.each { |usr| create :lti_user, user: usr, lti_client: lti_deployment.lti_client }
    end
    it 'does not get unreleased grades' do
      expect(lti_deployment.get_grade_entry_form_marks(assessment)).to be_empty
    end
    it 'does get released grades for an assignment with released grades' do
      assessment.grade_entry_students.first.update!(released_to_student: true)
      expect(lti_deployment.get_grade_entry_form_marks(assessment)).not_to be_empty
    end
    it 'does get all released grades' do
      assessment.grade_entry_students.all.update!(released_to_student: true)
      expect(lti_deployment.get_grade_entry_form_marks(assessment).length).to eq(assessment.grade_entry_students.count)
    end
  end
end
