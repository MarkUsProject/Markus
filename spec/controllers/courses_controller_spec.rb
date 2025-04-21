describe CoursesController do
  let(:instructor) { create(:instructor) }
  let(:course) { instructor.course }
  let(:student) { create(:student, course: course) }
  let(:ta) { create(:ta, course: course) }

  describe 'role switching methods' do
    subject do
      post_as instructor, :switch_role, params: { id: course.id, effective_user_login: end_user.user_name }
    end

    describe '#switch_role' do
      let(:temp_user) { create(:end_user) }

      it 'fails when no username is provided' do
        post_as instructor, :switch_role, params: { id: course.id }
        expect(response).to have_http_status(:not_found)
      end

      it 'fails when an invalid username is provided' do
        username = temp_user.user_name
        temp_user.destroy
        post_as instructor, :switch_role, params: { id: course.id, effective_user_login: username }
        expect(response).to have_http_status(:not_found)
      end

      context 'when switching to users not in the course' do
        let(:course2) { create(:course) }
        let(:instructor2) { create(:instructor, course: course2) }
        let(:student2) { create(:student, course: course2) }
        let(:ta2) { create(:ta, course: course2) }

        it 'fails the switch to an instructor' do
          post_as instructor, :switch_role, params: { id: course.id, effective_user_login: instructor2.user_name }
          expect(response).to have_http_status(:not_found)
        end

        it 'fails the switch to a student' do
          post_as instructor, :switch_role, params: { id: course.id, effective_user_login: student2.user_name }
          expect(response).to have_http_status(:not_found)
        end

        it 'fails the switch to a ta' do
          post_as instructor, :switch_role, params: { id: course.id, effective_user_login: ta2.user_name }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when switching to instructors in the course' do
        let(:second_instructor) { create(:instructor, course: course) }

        it 'fails the switch to the current instructor' do
          post_as instructor, :switch_role, params: { id: course.id, effective_user_login: instructor.user_name }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'fails the switch to another instructor' do
          post_as instructor, :switch_role, params: { id: course.id, effective_user_login: second_instructor.user_name }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'fails to switch to an admin' do
          admin = create(:admin_role, course: course)
          post_as instructor, :switch_role, params: { id: course.id, effective_user_login: admin.user_name }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        context 'when the current user is an admin' do
          let(:admin_role) { create(:admin_role, course: course) }

          it 'fails the switch to the current admin' do
            post_as admin_role, :switch_role, params: { id: course.id, effective_user_login: admin_role.user_name }
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it 'switches to another instructor' do
            post_as admin_role, :switch_role, params: { id: course.id, effective_user_login: instructor.user_name }
            expect(response).to have_http_status(:success)
          end

          it 'fails to switch to another admin' do
            admin = create(:admin_role, course: course)
            post_as admin_role, :switch_role, params: { id: course.id, effective_user_login: admin.user_name }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      context 'when switching to a student in the course' do
        let(:end_user) { create(:student, course: course) }

        before do
          subject
        end

        it 'succeeds' do
          expect(response).to have_http_status(:success)
        end

        it "sets session's role_switch_course_id to current_course.id when switching role succeeds" do
          expect(session[:role_switch_course_id]).to eq(course.id)
        end

        it "sets session's redirect_url to nil when switching role succeeds" do
          expect(session[:redirect_url]).to be_nil
        end

        it "sets session's user_name to the student's user_name" do
          expect(session[:user_name]).to eq(end_user.user_name)
        end
      end

      context 'when switching to a TA in the course' do
        let(:end_user) { create(:ta, course: course) }

        before do
          subject
        end

        it 'succeeds' do
          expect(response).to have_http_status(:success)
        end

        it "sets session's role_switch_course_id to current_course.id when switching role succeeds" do
          expect(session[:role_switch_course_id]).to eq(course.id)
        end

        it "sets session's redirect_url to nil when switching role succeeds" do
          expect(session[:redirect_url]).to be_nil
        end

        it "sets session's user_name to the TA's user_name" do
          expect(session[:user_name]).to eq(end_user.user_name)
        end
      end
    end

    describe '#clear_role_switch_session' do
      before do
        subject
        @controller = CoursesController.new
        get_as instructor, :clear_role_switch_session, params: { id: course.id }
      end

      context 'when previously switched to a TA in the course' do
        let(:end_user) { create(:ta, course: course) }

        it 'succeeds and has a redirect status' do
          expect(response).to have_http_status(:found)
        end

        it 'redirects to the current course page' do
          expect(response).to redirect_to action: :show, id: course.id
        end

        it "sets this session's username to nil" do
          expect(session[:user_name]).to be_nil
        end

        it "sets this session's role_switch_course_id to nil" do
          expect(session[:role_switch_course_id]).to be_nil
        end
      end

      context 'when previously switched to a student in the course' do
        let(:end_user) { create(:student, course: course) }

        it 'succeeds and has a redirect status' do
          expect(response).to have_http_status(:found)
        end

        it 'redirects to the current course page' do
          expect(response).to redirect_to action: :show, id: course.id
        end

        it "sets this session's username to nil" do
          expect(session[:user_name]).to be_nil
        end

        it "sets this session's role_switch_course_id to nil" do
          expect(session[:role_switch_course_id]).to be_nil
        end
      end
    end
  end

  context 'accessing course pages' do
    it 'responds with success on index' do
      get_as instructor, :index
      expect(response).to have_http_status(:ok)
    end

    it 'responds with success on show as an instructor' do
      get_as instructor, :show, params: { id: course }
      expect(response).to have_http_status(:ok)
    end

    it 'redirects to assignments on show as a student' do
      get_as student, :show, params: { id: course }
      expect(response).to redirect_to(course_assignments_path(course.id))
    end

    it 'redirects to assignments on show as a ta' do
      get_as ta, :show, params: { id: course }
      expect(response).to redirect_to(course_assignments_path(course.id))
    end

    it 'responds with success on edit' do
      get_as instructor, :edit, params: { id: course }
      expect(response).to have_http_status(:ok)
    end

    context 'updating course visibility' do
      context 'as an authorized instructor' do
        it 'responds with success on update' do
          put_as instructor, :update,
                 params: { id: course.id, course: { display_name: 'Intro to CS', is_hidden: false } }
          expect(response).to have_http_status(:found)
        end

        it 'updates the course' do
          put_as instructor, :update,
                 params: { id: course.id, course: { display_name: 'Intro to CS', is_hidden: false } }
          updated_course = Course.find(course.id)
          expected_course_data = {
            name: course.name,
            display_name: 'Intro to CS',
            is_hidden: false
          }
          updated_course_data = {
            name: updated_course.name,
            display_name: updated_course.display_name,
            is_hidden: updated_course.is_hidden
          }
          expect(updated_course_data).to eq(expected_course_data)
        end

        it 'does not update the course name' do
          put_as instructor, :update,
                 params: { id: course.id, course: { name: 'CS101' } }
          updated_course = Course.find(course.id)
          expect(updated_course.name).not_to eq('CS101')
        end

        context 'updating the autotest_url' do
          it 'does not update the autotest_url as an instructor' do
            expect(AutotestResetUrlJob).not_to receive(:perform_later)
            put_as instructor, :update, params: { id: course.id, course: { autotest_url: 'http://example.com' } }
          end

          it 'does update the autotest_url as an admin' do
            expect(AutotestResetUrlJob).to receive(:perform_later) do |course_, url|
              expect(course_).to eq course
              expect(url).to eq 'http://example.com'
              nil # mocked return value
            end
            put_as create(:admin_role), :update,
                   params: { id: course.id, course: { autotest_url: 'http://example.com' } }
          end
        end

        it 'does not update the max_file_size as an instructor' do
          put_as instructor, :update, params: { id: course.id, course: { max_file_size: 200 } }
          updated_course = Course.find(course.id)
          expect(updated_course.max_file_size).not_to eq(200)
        end

        it 'does update the max_file_size as an admin' do
          put_as create(:admin_role), :update, params: { id: course.id, course: { max_file_size: 200 } }
          updated_course = Course.find(course.id)
          expect(updated_course.max_file_size).to eq(200)
        end

        it 'does not update when parameters are invalid' do
          expected_course_data = {
            name: course.name,
            display_name: course.display_name,
            is_hidden: course.is_hidden
          }
          put_as instructor, :update,
                 params: { id: course.id, course: { name: 'CS101', is_hidden: nil } }
          updated_course = Course.find(course.id)
          updated_course_data = {
            name: updated_course.name,
            display_name: updated_course.display_name,
            is_hidden: updated_course.is_hidden
          }
          expect(updated_course_data).to eq(expected_course_data)
        end
      end

      context 'as an unauthorized user' do
        shared_examples 'cannot update course' do
          it 'responds with 403' do
            put_as user, :update,
                   params: { id: course.id, course: { name: 'CS101', is_hidden: !course.is_hidden } }
            expect(response).to have_http_status(:forbidden)
          end

          it 'fails to update the course visibility when user unauthorized' do
            expected_course_data = {
              name: course.name,
              display_name: course.display_name,
              is_hidden: course.is_hidden
            }
            put_as user, :update,
                   params: { id: course.id, course: { name: 'CS101', is_hidden: !course.is_hidden } }
            updated_course = Course.find(course.id)
            updated_course_data = {
              name: updated_course.name,
              display_name: updated_course.display_name,
              is_hidden: updated_course.is_hidden
            }
            expect(updated_course_data).to eq(expected_course_data)
          end
        end

        context 'TA' do
          let(:user) { create(:ta, manage_assessments: true, run_tests: true, manage_submissions: true) }

          it_behaves_like 'cannot update course'
        end

        context 'Student' do
          let(:user) { create(:student) }

          it_behaves_like 'cannot update course'
        end
      end
    end
  end

  describe '#upload_assignments' do
    it_behaves_like 'a controller supporting upload', route_name: :upload_assignments do
      let(:params) { { id: course.id } }
    end

    before do
      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good = fixture_file_upload('assignments/form_good.csv', 'text/csv')
      allow(@file_good).to receive(:read).and_return(
        File.read(fixture_file_upload('assignments/form_good.csv', 'text/csv'))
      )
      @file_good_yml = fixture_file_upload('assignments/form_good.yml', 'text/yaml')
      allow(@file_good_yml).to receive(:read).and_return(
        File.read(fixture_file_upload('assignments/form_good.yml', 'text/yaml'))
      )

      @file_invalid_column = fixture_file_upload('assignments/form_invalid_column.csv', 'text/csv')
      allow(@file_invalid_column).to receive(:read).and_return(
        File.read(fixture_file_upload('assignments/form_invalid_column.csv', 'text/csv'))
      )

      # This must line up with the second entry in the file_good
      @test_asn1 = 'ATest1'
      @test_asn2 = 'ATest2'
    end

    it 'accepts a valid file' do
      post_as instructor, :upload_assignments, params: { id: course.id, upload_file: @file_good }

      expect(response).to have_http_status(:found)
      test1 = Assignment.find_by(short_identifier: @test_asn1)
      expect(test1).not_to be_nil
      test2 = Assignment.find_by(short_identifier: @test_asn2)
      expect(test2).not_to be_nil
      expect(flash[:error]).to be_nil
      expect(flash[:success]).to have_message(I18n.t('upload_success', count: 2))
      expect(response).to redirect_to(course_assignments_path(course))
    end

    it 'accepts a valid YAML file' do
      post_as instructor, :upload_assignments, params: { id: course.id, upload_file: @file_good_yml }

      expect(response).to have_http_status(:found)
      test1 = Assignment.find_by(short_identifier: @test_asn1)
      expect(test1).not_to be_nil
      test2 = Assignment.find_by(short_identifier: @test_asn2)
      expect(test2).not_to be_nil
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(course_assignments_path(course))
    end

    it 'does not accept files with invalid columns' do
      post_as instructor, :upload_assignments, params: { id: course.id, upload_file: @file_invalid_column }

      expect(response).to have_http_status(:found)
      expect(flash[:error]).not_to be_empty
      test = Assignment.find_by(short_identifier: @test_asn2)
      expect(test).to be_nil
      expect(response).to redirect_to(course_assignments_path(course))
    end
  end

  context 'CSV_Downloads' do
    let(:csv_options) do
      { type: 'text/csv', filename: 'assignments.csv', disposition: 'attachment' }
    end
    let!(:assignment) { create(:assignment) }

    it 'responds with appropriate status' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'csv' }
      expect(response).to have_http_status(:ok)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'csv' }
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    it 'expects a call to send_data' do
      # generate the expected csv string
      csv_data = []
      Assignment::DEFAULT_FIELDS.map do |f|
        csv_data << assignment.public_send(f)
      end
      new_data = csv_data.join(',') + "\n"
      expect(@controller).to receive(:send_data).with(new_data, csv_options) {
        # to prevent a 'missing template' error
        @controller.head :ok
      }
      get_as instructor, :download_assignments, params: { id: course.id, format: 'csv' }
    end

    # parse header object to check for the right content type
    it 'returns text/csv type' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'csv' }
      expect(response.media_type).to eq 'text/csv'
    end

    # parse header object to check for the right file naming convention
    it 'filename passes naming conventions' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'csv' }
      filename = response.header['Content-Disposition'].split[1].split('"').second
      expect(filename).to eq 'assignments.csv'
    end
  end

  describe '#download_assignments' do
    let(:yml_options) do
      { type: 'text/yml', filename: 'assignments.yml', disposition: 'attachment' }
    end

    before { create(:assignment) }

    it 'responds with appropriate status' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
      expect(response).to have_http_status(:ok)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    it 'expects a call to send_data' do
      # generate the expected yml string
      assignments = Assignment.all
      map = {}
      map[:assignments] = assignments.map do |assignment|
        m = {}
        Assignment::DEFAULT_FIELDS.each do |f|
          m[f] = assignment.public_send(f)
        end
        m
      end
      map = map.to_yaml
      expect(@controller).to receive(:send_data).with(map, yml_options) {
        # to prevent a 'missing template' error
        @controller.head :ok
      }
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
    end

    # parse header object to check for the right content type
    it 'returns text/yml type' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
      expect(response.media_type).to eq 'text/yml'
    end

    # parse header object to check for the right file naming convention
    it 'filename passes naming conventions' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
      filename = response.header['Content-Disposition'].split[1].split('"').second
      expect(filename).to eq 'assignments.yml'
    end
  end

  describe 'visiting index page' do
    let(:course1) { create(:course, is_hidden: false) }
    let(:course2) { create(:course, is_hidden: false) }
    let(:end_user) { create(:end_user) }

    context 'Student' do
      before do
        create(:student, course: course1, user: end_user)
        create(:student, course: course2, user: end_user)
      end

      it 'responds with a list sorted by courses.name' do
        get_as end_user, :index, params: { format: 'json' }
        parsed_body = response.parsed_body['data']
        sorted_body = parsed_body.sort_by { |k| k['courses.name'] }
        expect(parsed_body).to eq sorted_body
      end
    end

    context 'TA' do
      before do
        create(:ta, course: course1, user: end_user)
        create(:ta, course: course2, user: end_user)
      end

      it 'responds with a list sorted by courses.name' do
        get_as end_user, :index, params: { format: 'json' }
        parsed_body = response.parsed_body['data']
        sorted_body = parsed_body.sort_by { |k| k['courses.name'] }
        expect(parsed_body).to eq sorted_body
      end
    end

    context 'Instructor' do
      before do
        create(:instructor, course: course1, user: end_user)
        create(:instructor, course: course2, user: end_user)
      end

      it 'responds with a list sorted by courses.name' do
        get_as end_user, :index, params: { format: 'json' }
        parsed_body = response.parsed_body['data']
        sorted_body = parsed_body.sort_by { |k| k['courses.name'] }
        expect(parsed_body).to eq sorted_body
      end
    end
  end

  describe 'destroying lti deployments' do
    let!(:lti_deployment) { create(:lti_deployment, course: course) }
    let(:admin_role) { create(:admin_role, course: course) }

    it 'redirects if the user is not logged in' do
      delete :destroy_lti_deployment, params: { id: course.id, lti_deployment_id: lti_deployment.id }
      expect(response).to have_http_status(:found)
    end

    it 'returns an error for students' do
      delete_as student, :destroy_lti_deployment, params: { id: course.id, lti_deployment_id: lti_deployment.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns an error for TAs' do
      delete_as ta, :destroy_lti_deployment, params: { id: course.id, lti_deployment_id: lti_deployment.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'redirects back as an instructor' do
      delete_as instructor, :destroy_lti_deployment, params: { id: course.id, lti_deployment_id: lti_deployment.id }
      expect(response).to have_http_status(:see_other)
    end

    it 'redirects back as an admin' do
      delete_as admin_role, :destroy_lti_deployment, params: { id: course.id, lti_deployment_id: lti_deployment.id }
      expect(response).to have_http_status(:see_other)
    end

    it 'deletes the deployment' do
      delete_as instructor, :destroy_lti_deployment, params: { id: course.id, lti_deployment_id: lti_deployment.id }
      expect(LtiDeployment.count).to eq(0)
    end

    context 'with dependent line items' do
      before { create(:lti_line_item, lti_deployment: lti_deployment) }

      it 'deletes the line item' do
        delete_as instructor, :destroy_lti_deployment, params: { id: course.id, lti_deployment_id: lti_deployment.id }
        expect(LtiLineItem.count).to eq(0)
      end
    end

    context 'with dependent services' do
      before do
        create(:lti_service_namesrole, lti_deployment: lti_deployment)
        create(:lti_service_lineitem, lti_deployment: lti_deployment)
      end

      it 'deletes the dependent objects' do
        delete_as instructor, :destroy_lti_deployment, params: { id: course.id, lti_deployment_id: lti_deployment.id }
        expect(LtiService.count).to eq(0)
      end
    end

    context 'with lti users' do
      before { create(:lti_user, user: student.user) }

      it 'does not delete users' do
        delete_as instructor, :destroy_lti_deployment, params: { id: course.id, lti_deployment_id: lti_deployment.id }
        expect(LtiUser.count).to eq(1)
      end
    end
  end

  describe 'get lti deployments' do
    let!(:lti_deployment) { create(:lti_deployment, course: course) }

    it 'returns the deployment' do
      get_as instructor, :lti_deployments, params: { id: course.id }
      expect(response.parsed_body[0]['id']).to eq(lti_deployment.id)
    end

    it 'returns the nested lti client' do
      get_as instructor, :lti_deployments, params: { id: course.id }
      expect(response.parsed_body[0]).to have_key('lti_client')
    end
  end

  describe 'sync_roster' do
    let!(:lti_deployment) { create(:lti_deployment, course: course) }

    before do
      create(:lti_service_namesrole, lti_deployment: lti_deployment)
      create(:lti_service_lineitem, lti_deployment: lti_deployment)
    end

    after do
      Resque.remove_schedule("LtiRosterSync_#{lti_deployment.id}_#{root_path.tr!('/', '')}")
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'enqueues a job' do
      expect do
        post_as instructor, :sync_roster,
                params: { id: course.id, lti_deployment_id: lti_deployment.id, include_students: 'true' }
      end.to have_enqueued_job
    end

    it 'creates a schedule' do
      post_as instructor, :sync_roster,
              params: { id: course.id, lti_deployment_id: lti_deployment.id,
                        include_students: 'true', automatic_sync: 'true' }
      expect(Resque.fetch_schedule("LtiRosterSync_#{lti_deployment.id}_#{root_path.tr!('/', '')}")).not_to be_nil
    end

    it 'unsets a schedule' do
      post_as instructor, :sync_roster,
              params: { id: course.id, lti_deployment_id: lti_deployment.id,
                        include_students: 'true', automatic_sync: 'true' }
      post_as instructor, :sync_roster,
              params: { id: course.id, lti_deployment_id: lti_deployment.id, include_students: 'true' }
      expect(Resque.fetch_schedule("LtiRosterSync_#{lti_deployment.id}_#{root_path.tr!('/', '')}")).to be_nil
    end

    it 'does not raise an error when no schedule can be unset' do
      post_as instructor, :sync_roster,
              params: { id: course.id, lti_deployment_id: lti_deployment.id, include_students: 'true' }
      expect(response).to have_http_status :redirect
    end
  end
end
