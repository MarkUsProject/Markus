describe LtiHelper do
  let(:scope) { LtiDeployment::LTI_SCOPES[:names_role] }
  let(:course) { create(:course) }
  let(:lti_deployment) { create(:lti_deployment, course: course) }

  before do
    allow(File).to receive(:read).and_call_original
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

  describe '#get_students' do
    let!(:lti_service_namesrole) { create(:lti_service_namesrole, lti_deployment: lti_deployment) }
    let!(:student) { create(:student, course: course) }
    let(:scope) { LtiDeployment::LTI_SCOPES[:names_role] }
    let(:memberships) do
      [{ status: 'Active', name: 'student.display_name',
         picture: 'http://example.com/picture.png',
         given_name: 'student.first_name',
         family_name: 'student.last_name',
         lis_person_sourcedid: student.user_name,
         email: 'student_email',
         user_id: 'lti_user_id',
         lti11_legacy_user_id: 'legacy_lti_user_id',
         roles:
           [
             LtiDeployment::LTI_ROLES[:learner]
           ] },
       { status: 'Active', name: 'second user',
         picture: 'http://example.com/picture.png',
         given_name: 'student.first_name',
         family_name: 'student.last_name',
         lis_person_sourcedid: 'second_username',
         email: 'test@example.com',
         user_id: 'another_user_id',
         lti11_legacy_user_id: 'legacy_lti_user_id',
         roles:
           [
             LtiDeployment::LTI_ROLES[:learner]
           ] },
       { status: 'Active', name: 'third user',
         picture: 'http://example.com/picture.png',
         given_name: 'student.first_name',
         family_name: 'student.last_name',
         lis_person_sourcedid: 'third_username',
         email: 'test2@example.com',
         user_id: 'third_user_id',
         lti11_legacy_user_id: 'legacy_lti_user_id',
         roles:
           [
             LtiDeployment::LTI_ROLES[:ta]
           ] },
       { status: 'Active', name: 'fourth user',
         picture: 'http://example.com/picture.png',
         given_name: 'student.first_name',
         family_name: 'student.last_name',
         lis_person_sourcedid: 'fourth_username',
         email: 'test3@example.com',
         user_id: 'fourth_user_id',
         lti11_legacy_user_id: 'legacy_lti_user_id',
         roles:
           [
             LtiDeployment::LTI_ROLES[:instructor]
           ] }]
    end
    let(:lti_students) do
      {
        id: 'http://test.host/api/lti/courses/1/names_and_roles?role=Learner',
        context: { id: '4dde05e8ca1973bcca9bffc13e1548820eee93a3',
                   label: 'tst1', title: 'test course' },
        members: memberships
      }.to_json
    end

    context 'when syncing only learners' do
      before do
        allow_any_instance_of(LtiDeployment).to(
          receive(:send_lti_request!).and_return(OpenStruct.new(body: lti_students))
        )
      end

      context 'when run by an admin user' do
        subject do
          roster_sync lti_deployment, course, [LtiDeployment::LTI_ROLES[:learner]], can_create_users: true,
                                                                                    can_create_roles: true
        end

        it 'creates a new user' do
          subject
          expect(EndUser.count).to eq(2)
        end

        it 'does not create tas' do
          subject
          expect(Ta.count).to eq(0)
        end

        it 'does not create instructors' do
          subject
          expect(Instructor.count).to eq(0)
        end

        it 'creates roles with an admin role' do
          subject
          expect(Student.count).to eq(2)
        end

        it 'creates lti users' do
          subject
          expect(LtiUser.count).to eq(2)
        end
      end

      context 'when run by an instructor' do
        subject do
          roster_sync lti_deployment, course, [LtiDeployment::LTI_ROLES[:learner]], can_create_users: true,
                                                                                    can_create_roles: true
        end

        it 'does create users' do
          subject
          expect(EndUser.count).to eq(2)
        end

        it 'does not create tas' do
          subject
          expect(Ta.count).to eq(0)
        end

        it 'does not create instructors' do
          subject
          expect(Instructor.count).to eq(0)
        end

        context 'with a new enduser' do
          before { create(:end_user, user_name: 'second_username') }

          it 'creates roles' do
            subject
            expect(Student.count).to eq(2)
          end

          it 'creates lti users' do
            subject
            expect(LtiUser.count).to eq(2)
          end
        end
      end
    end

    context 'when syncing learners and TAs' do
      before do
        allow_any_instance_of(LtiDeployment).to(
          receive(:send_lti_request!).and_return(OpenStruct.new(body: lti_students))
        )
      end

      context 'when run by an admin user' do
        subject do
          roster_sync lti_deployment, course, [LtiDeployment::LTI_ROLES[:learner], LtiDeployment::LTI_ROLES[:ta]],
                      can_create_users: true, can_create_roles: true
        end

        it 'creates a new user' do
          subject
          expect(EndUser.count).to eq(3)
        end

        it 'does create tas' do
          subject
          expect(Ta.count).to eq(1)
        end

        it 'does not create instructors' do
          subject
          expect(Instructor.count).to eq(0)
        end

        it 'creates roles with an admin role' do
          subject
          expect(Student.count).to eq(2)
        end

        it 'creates lti users' do
          subject
          expect(LtiUser.count).to eq(3)
        end
      end

      context 'when run by an instructor' do
        subject do
          roster_sync lti_deployment, course, [LtiDeployment::LTI_ROLES[:learner], LtiDeployment::LTI_ROLES[:ta]],
                      can_create_users: true, can_create_roles: true
        end

        it 'does create users' do
          subject
          expect(EndUser.count).to eq(3)
        end

        it 'does create tas' do
          subject
          expect(Ta.count).to eq(1)
        end

        it 'does not create instructors' do
          subject
          expect(Instructor.count).to eq(0)
        end

        context 'with a new enduser' do
          before { create(:end_user, user_name: 'second_username') }

          it 'creates roles' do
            subject
            expect(Student.count).to eq(2)
          end

          it 'creates lti users' do
            subject
            expect(LtiUser.count).to eq(3)
          end
        end
      end
    end

    context 'when syncing learners, TAs, and instructors' do
      before do
        allow_any_instance_of(LtiDeployment).to(
          receive(:send_lti_request!).and_return(OpenStruct.new(body: lti_students))
        )
      end

      context 'when run by an admin user' do
        subject do
          roster_sync lti_deployment, course, [LtiDeployment::LTI_ROLES[:learner], LtiDeployment::LTI_ROLES[:ta],
                                               LtiDeployment::LTI_ROLES[:instructor]],
                      can_create_users: true, can_create_roles: true
        end

        it 'creates a new user' do
          subject
          expect(EndUser.count).to eq(4)
        end

        it 'does create tas' do
          subject
          expect(Ta.count).to eq(1)
        end

        it 'does create instructors' do
          subject
          expect(Instructor.count).to eq(1)
        end

        it 'creates roles with an admin role' do
          subject
          expect(Student.count).to eq(2)
        end

        it 'creates lti users' do
          subject
          expect(LtiUser.count).to eq(4)
        end
      end

      context 'when run by an instructor' do
        subject do
          roster_sync lti_deployment, course, [LtiDeployment::LTI_ROLES[:learner], LtiDeployment::LTI_ROLES[:ta],
                                               LtiDeployment::LTI_ROLES[:instructor]],
                      can_create_users: true, can_create_roles: true
        end

        it 'does create users' do
          subject
          expect(EndUser.count).to eq(4)
        end

        it 'does create tas' do
          subject
          expect(Ta.count).to eq(1)
        end

        it 'does create instructors' do
          subject
          expect(Instructor.count).to eq(1)
        end

        context 'with a new enduser' do
          before { create(:end_user, user_name: 'second_username') }

          it 'creates roles' do
            subject
            expect(Student.count).to eq(2)
          end

          it 'creates lti users' do
            subject
            expect(LtiUser.count).to eq(4)
          end
        end
      end
    end

    context 'with paginated results' do
      subject do
        roster_sync lti_deployment, course, [LtiDeployment::LTI_ROLES[:learner], LtiDeployment::LTI_ROLES[:ta],
                                             LtiDeployment::LTI_ROLES[:instructor]],
                    can_create_users: true, can_create_roles: true
      end

      let(:url) { lti_service_namesrole.url }

      before do
        stub_request(:any, url).with(
          headers: {
            'Accept' => '*/*'
          }, body: {}
        ).to_return(body: { id: 'http://test.host/api/lti/courses/1/names_and_roles?role=Learner',
                            context: { id: '4dde05e8ca1973bcca9bffc13e1548820eee93a3',
                                       label: 'tst1', title: 'test course' }, members: memberships[0..1] }.to_json,
                    headers: { 'Link' => "<http://example.com?page=1>; rel='current',<#{url}?page=2>; rel='next',\
                      <#{url}?page=1>; rel='first',<#{url}?page=3>; rel='last'" })
        stub_request(:any, "#{url}?page=2").with(
          headers: {
            'Accept' => '*/*'
          }, body: {}
        ).to_return(body: { id: 'http://test.host/api/lti/courses/1/names_and_roles?role=Learner',
                            context: { id: '4dde05e8ca1973bcca9bffc13e1548820eee93a3',
                                       label: 'tst1', title: 'test course' }, members: [memberships[2]] }.to_json,
                    headers: { 'Link' => "<http://example.com?page=2>; rel='current',<#{url}?page=3>; rel='next',\
                      <#{url}?page=1>; rel='first',<#{url}?page=3>;" })
        stub_request(:any, "#{url}?page=3").with(
          headers: {
            'Accept' => '*/*'
          }, body: {}
        ).to_return(body: { id: 'http://test.host/api/lti/courses/1/names_and_roles?role=Learner',
                            context: { id: '4dde05e8ca1973bcca9bffc13e1548820eee93a3',
                                       label: 'tst1', title: 'test course' }, members: [memberships[3]] }.to_json,
                    headers: { 'Link' => "<http://example.com?page=3>; rel='current',<#{url}?page=1>;\
                      rel='first',<#{url}?page=3>; rel='last'" })
      end

      it 'does create users' do
        subject
        expect(EndUser.count).to eq(4)
      end

      it 'does create tas' do
        subject
        expect(Ta.count).to eq(1)
      end

      it 'does create instructors' do
        subject
        expect(Instructor.count).to eq(1)
      end

      context 'with a new enduser' do
        before { create(:end_user, user_name: 'second_username') }

        it 'creates roles' do
          subject
          expect(Student.count).to eq(2)
        end

        it 'creates lti users' do
          subject
          expect(LtiUser.count).to eq(4)
        end
      end
    end
  end

  describe '#get_assignment_grades' do
    let(:student1) { create(:student, course: course) }
    let!(:assessment) { create(:assignment_with_criteria_and_results, course: course) }
    let!(:assessment2) { create(:assignment_with_criteria_and_results, course: course) }

    context 'with lti user ids' do
      before do
        User.find_each do |usr|
          create :lti_user, user: usr, lti_client: lti_deployment.lti_client if LtiUser.find_by(user: usr).nil?
        end
        Result.joins(grouping: :assignment)
              .where('assignment.id': assessment.id).update!(released_to_students: true)
      end

      it 'successfully gets grades for an assignment with released grades' do
        expect(get_assignment_marks(lti_deployment, assessment)).not_to be_empty
      end

      it 'does not get unreleased grades' do
        expect(get_assignment_marks(lti_deployment, assessment2)).to be_empty
      end

      it 'does not get unreleased grades for an assignment with released grades' do
        Result.joins(grouping: :assignment)
              .where('assignment.id': assessment2.id).first.update!(released_to_students: true)
        expect(get_assignment_marks(lti_deployment, assessment2)).not_to be_empty
      end

      it 'does return a hash' do
        expect(get_assignment_marks(lti_deployment, assessment)).to be_instance_of(Hash)
      end

      it 'has float values' do
        expect(get_assignment_marks(lti_deployment, assessment).first[1]).to be_a(Numeric)
      end
    end

    context 'with some lti users' do
      before do
        create(:lti_user, user: User.first, lti_client: lti_deployment.lti_client)
        Result.joins(grouping: :assignment)
              .where('assignment.id': assessment.id).update!(released_to_students: true)
      end

      it 'does get grades for a user with an lti id' do
        expect(get_assignment_marks(lti_deployment, assessment)).not_to be_empty
      end
    end
  end

  describe '#get_grade_entry_form_marks' do
    let!(:assessment) do
      create(:student, course: course)  # :grade_entry_form_with_data only populates marks for existing students
      create(:grade_entry_form_with_data, course: course)
    end

    context 'with lti user ids' do
      before do
        User.find_each { |usr| create(:lti_user, user: usr, lti_client: lti_deployment.lti_client) }
      end

      it 'does not get unreleased grades' do
        expect(get_grade_entry_form_marks(lti_deployment, assessment)).to be_empty
      end

      it 'does get released grades for an assignment with released grades' do
        assessment.grade_entry_students.first.update!(released_to_student: true)
        expect(get_grade_entry_form_marks(lti_deployment, assessment)).not_to be_empty
      end

      it 'does get all released grades' do
        assessment.grade_entry_students.all.update!(released_to_student: true)
        expect(get_grade_entry_form_marks(lti_deployment,
                                          assessment).length).to eq(assessment.grade_entry_students.count)
      end

      it 'does return a hash' do
        assessment.grade_entry_students.all.update!(released_to_student: true)
        expect(get_grade_entry_form_marks(lti_deployment, assessment)).to be_instance_of(Hash)
      end

      it 'has float values' do
        assessment.grade_entry_students.all.update!(released_to_student: true)
        expect(get_grade_entry_form_marks(lti_deployment, assessment).first[1]).to be_a(Numeric)
      end
    end

    context 'with students with no lti user' do
      it 'does not return any grades' do
        assessment.grade_entry_students.first.update!(released_to_student: true)
        expect(get_grade_entry_form_marks(lti_deployment, assessment)).to be_empty
      end
    end

    context 'with some lti users' do
      before { create(:lti_user, user: User.first, lti_client: lti_deployment.lti_client) }

      it 'does get grades for a user with an lti id' do
        assessment.grade_entry_students.first.update!(released_to_student: true)
        expect(get_grade_entry_form_marks(lti_deployment, assessment)).not_to be_empty
      end
    end
  end

  describe 'grade_sync' do
    let(:student) { create(:student) }
    let!(:assessment) { create(:assignment_with_criteria_and_results, course: course) }
    let(:scope) { [LtiDeployment::LTI_SCOPES[:score], LtiDeployment::LTI_SCOPES[:results]] }
    let(:result_score) { 0.83 }
    let(:result_max) { 1 }
    let(:user_id) { '5323497' }

    before do
      create(:lti_service_lineitem, lti_deployment: lti_deployment)
      create(:lti_line_item, assessment: assessment, lti_deployment: lti_deployment)

      Result.joins(grouping: :assignment)
            .where('assignment.id': assessment.id).update!(released_to_students: true)
      User.find_each { |usr| create(:lti_user, user: usr, lti_client: lti_deployment.lti_client) }
      allow_any_instance_of(LtiHelper).to(receive(:create_or_update_lti_assessment)
                                            .and_return(OpenStruct.new(
                                                          body: { id: 'https://test.example.com/line_items/1' }.to_json
                                                        )))
      allow_any_instance_of(LtiHelper).to(receive(:get_current_results)).and_return(OpenStruct.new(body: [{
        id: 'https://lms.example.com/context/2923/lineitems/1/results/5323497',
        scoreOf: 'https://lms.example.com/context/2923/lineitems/1',
        userId: user_id,
        resultScore: result_score,
        resultMaximum: result_max,
        comment: 'This is exceptional work.'
      }].to_json))
      allow(lti_deployment).to(
        receive(:send_lti_request!).and_return(
          OpenStruct.new(body: { result: 'https://test.example.com/results/1' }.to_json)
        )
      )
    end

    it 'does send grades' do
      expect(grade_sync(lti_deployment, assessment)).not_to be_empty
    end

    context 'when there are already grades on the LMS' do
      let(:lti_user) { create(:lti_user, user: student.user, lti_client: LtiClient.first) }

      it 'does not send grades that are the same' do
        expect(lti_deployment).to receive(:send_lti_request!).exactly(3).times
        grade_sync(lti_deployment, assessment)
      end
    end
  end

  describe '#create_or_update_lti_assessment' do
    subject { create_or_update_lti_assessment(lti_deployment, assessment) }

    let(:assessment) { create(:assignment) }

    before do
      create(:lti_service_lineitem, lti_deployment: lti_deployment)
      allow(lti_deployment).to(receive(:send_lti_request!)
                                 .and_return(OpenStruct.new(
                                               body: { id: 'https://test.example.com/lineitems/1' }.to_json
                                             )))
    end

    it 'does create a line item' do
      subject
      expect(LtiLineItem.count).to eq(1)
    end

    context 'when a line item already exists' do
      before { create(:lti_line_item, lti_deployment: lti_deployment, assessment: assessment) }

      it 'does not create a new line item' do
        expect { subject }.not_to(change { LtiLineItem.count })
      end

      it 'does update the line item id' do
        subject
        expect(LtiLineItem.first.lti_line_item_id).to eq('https://test.example.com/lineitems/1')
      end
    end
  end
end
