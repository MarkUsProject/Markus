describe CoursesController do
  let(:instructor) { create :instructor }
  let(:course) { instructor.course }
  let(:student) { create :student, course: course }
  let(:ta) { create :ta, course: course }

  describe 'role switching methods' do
    let(:subject) do
      post_as instructor, :switch_role, params: { id: course.id, effective_user_login: end_user.user_name }
    end

    describe '#switch_role' do
      let(:temp_user) { create :end_user }

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
        let(:course2) { create :course }
        let(:instructor2) { create :instructor, course: course2 }
        let(:student2) { create :student, course: course2 }
        let(:ta2) { create :ta, course: course2 }

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
        let(:second_instructor) { create :instructor, course: course }

        it 'fails the switch to the current instructor' do
          post_as instructor, :switch_role, params: { id: course.id, effective_user_login: instructor.user_name }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'fails the switch to another instructor' do
          post_as instructor, :switch_role, params: { id: course.id, effective_user_login: second_instructor.user_name }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'when switching to a student in the course' do
        let(:end_user) { create :student, course: course }

        before :each do
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
        let(:end_user) { create :ta, course: course }

        before :each do
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
      before :each do
        subject
        @controller = CoursesController.new
        get_as instructor, :clear_role_switch_session, params: { id: course.id }
      end

      context 'when previously switched to a TA in the course' do
        let(:end_user) { create :ta, course: course }

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
        let(:end_user) { create :student, course: course }

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
      expect(response.status).to eq(200)
    end
    it 'responds with success on show as an instructor' do
      get_as instructor, :show, params: { id: course }
      expect(response.status).to eq(200)
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
      expect(response).to have_http_status(200)
    end

    context 'updating course visibility' do
      context 'as an authorized instructor' do
        it 'responds with success on update' do
          put_as instructor, :update,
                 params: { id: course.id, course: { display_name: 'Intro to CS', is_hidden: false } }
          expect(response).to have_http_status(302)
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
            expect(response).to have_http_status(403)
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
          include_examples 'cannot update course'
        end

        context 'Student' do
          let(:user) { create :student }
          include_examples 'cannot update course'
        end
      end
    end
  end
  context '#upload_assignments' do
    include_examples 'a controller supporting upload', route_name: :upload_assignments do
      let(:params) { { id: course.id } }
    end

    before :each do
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

      expect(response.status).to eq(302)
      test1 = Assignment.find_by(short_identifier: @test_asn1)
      expect(test1).to_not be_nil
      test2 = Assignment.find_by(short_identifier: @test_asn2)
      expect(test2).to_not be_nil
      expect(flash[:error]).to be_nil
      expect(flash[:success].map { |f| extract_text f }).to eq([I18n.t('upload_success',
                                                                       count: 2)].map { |f| extract_text f })
      expect(response).to redirect_to(course_assignments_path(course))
    end

    it 'accepts a valid YAML file' do
      post_as instructor, :upload_assignments, params: { id: course.id, upload_file: @file_good_yml }

      expect(response.status).to eq(302)
      test1 = Assignment.find_by(short_identifier: @test_asn1)
      expect(test1).to_not be_nil
      test2 = Assignment.find_by(short_identifier: @test_asn2)
      expect(test2).to_not be_nil
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(course_assignments_path(course))
    end

    it 'does not accept files with invalid columns' do
      post_as instructor, :upload_assignments, params: { id: course.id, upload_file: @file_invalid_column }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
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
      expect(response.status).to eq(200)
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
  context 'YML_Downloads' do
    let(:yml_options) do
      { type: 'text/yml', filename: 'assignments.yml', disposition: 'attachment' }
    end
    let!(:assignment) { create(:assignment) }

    it 'responds with appropriate status' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
      expect(response.status).to eq(200)
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
    let(:course1) { create :course, is_hidden: false }
    let(:course2) { create :course, is_hidden: false }
    let(:end_user) { create :end_user }

    context 'Student' do
      let!(:student2c1) { create :student, course: course1, user: end_user }
      let!(:student2c2) { create :student, course: course2, user: end_user }
      it 'responds with a list sorted by courses.name' do
        get_as end_user, :index, params: { format: 'json' }
        parsed_body = JSON.parse(response.body)['data']
        sorted_body = parsed_body.sort_by { |k| k['courses.name'] }
        expect(parsed_body == sorted_body)
      end
    end

    context 'TA' do
      let!(:ta2c1) { create :ta, course: course1, user: end_user }
      let!(:ta2c2) { create :ta, course: course2, user: end_user }
      it 'responds with a list sorted by courses.name' do
        get_as end_user, :index, params: { format: 'json' }
        parsed_body = JSON.parse(response.body)['data']
        sorted_body = parsed_body.sort_by { |k| k['courses.name'] }
        expect(parsed_body == sorted_body)
      end
    end

    context 'Instructor' do
      let!(:instructor2c1) { create :instructor, course: course1, user: end_user }
      let!(:instructor2c2) { create :instructor, course: course2, user: end_user }
      it 'responds with a list sorted by courses.name' do
        get_as end_user, :index, params: { format: 'json' }
        parsed_body = JSON.parse(response.body)['data']
        sorted_body = parsed_body.sort_by { |k| k['courses.name'] }
        expect(parsed_body == sorted_body)
      end
    end
  end
end
