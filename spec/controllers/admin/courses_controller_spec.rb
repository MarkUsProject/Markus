describe Admin::CoursesController do
  context 'A user with unauthorized access' do
    let(:course) { create(:course) }

    shared_examples 'cannot access admin routes' do
      describe '#index' do
        it 'responds with 403' do
          get_as user, :index, format: 'json'
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#new' do
        it 'responds with 403' do
          get_as user, :new
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#create' do
        it 'responds with 403' do
          post_as user, :create,
                  params: { course: { name: 'CS101', display_name: 'Intro to CS', is_hidden: true } }
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#edit' do
        it 'responds with 403' do
          get_as user, :edit, params: { id: course.id }
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#update' do
        it 'responds with 403' do
          put_as user, :update,
                 params: { id: course.id, course: { name: 'CS101', display_name: 'Intro to CS', is_hidden: true } }
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#test_autotest_connection' do
        it 'responds with 403' do
          get_as user, :test_autotest_connection, params: { id: course.id }
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#reset_autotest_connection' do
        it 'responds with 403' do
          put_as user, :reset_autotest_connection, params: { id: course.id }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'Instructor' do
      let(:user) { create(:instructor, course: course) }

      it_behaves_like 'cannot access admin routes'
    end

    context 'TA' do
      let(:user) { create(:ta, course: course) }

      it_behaves_like 'cannot access admin routes'
    end

    context 'Student' do
      let(:user) { create(:student, course: course) }

      it_behaves_like 'cannot access admin routes'
    end
  end

  context 'An admin user' do
    let(:admin) { create(:admin_user) }
    let(:course) { create(:course) }

    describe '#index' do
      let!(:course1) { create(:course) }
      let!(:course2) { create(:course) }

      context 'when sending html' do
        it 'responds with 200' do
          get_as admin, :index, format: 'html'
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when sending json' do
        it 'responds with 200' do
          get_as admin, :index, format: 'json'
          expect(response).to have_http_status(:ok)
        end

        it 'sends the appropriate data' do
          get_as admin, :index, format: 'json'
          received_data = response.parsed_body.map(&:symbolize_keys)
          expected_data = [
            {
              id: course1.id,
              name: course1.name,
              display_name: course1.display_name,
              is_hidden: course1.is_hidden
            },
            {
              id: course2.id,
              name: course2.name,
              display_name: course2.display_name,
              is_hidden: course2.is_hidden
            }
          ]
          expect(received_data).to match_array(expected_data)
        end
      end
    end

    describe '#new' do
      it 'responds with 200' do
        get_as admin, :new
        expect(response).to have_http_status(:ok)
      end
    end

    describe '#create' do
      before do
        allow_any_instance_of(AutotestSetting).to receive(:register).and_return(1)
        allow_any_instance_of(AutotestSetting).to receive(:get_schema).and_return('{}')
      end

      it 'responds with 302' do
        post_as admin, :create, params: {
          course: { name: 'CSC207', display_name: 'Software Design', is_hidden: true, max_file_size: 1000 }
        }
        expect(response).to have_http_status(:found)
      end

      it 'creates the course' do
        post_as admin, :create, params: {
          course: { name: 'CSC207', display_name: 'Software Design', is_hidden: true, max_file_size: 1000 }
        }
        created_course = Course.find_by(name: 'CSC207')
        expected_course_data = {
          name: 'CSC207',
          display_name: 'Software Design',
          is_hidden: true,
          max_file_size: 1000
        }
        created_course_data = {
          name: created_course.name,
          display_name: created_course.display_name,
          is_hidden: created_course.is_hidden,
          max_file_size: created_course.max_file_size
        }
        expect(created_course_data).to eq(expected_course_data)
      end

      it 'does not update when parameters are invalid' do
        post_as admin, :create, params: { course: { name: 'CSC207', display_name: nil, is_hidden: true } }
        created_course = Course.find_by(name: 'CSC207')
        expect(created_course).to be_nil
      end

      it 'updates the autotest_url' do
        expect(AutotestResetUrlJob).to receive(:perform_later) do |course_, url|
          expect(course_).to eq Course.find_by(name: 'CSC207')
          expect(url).to eq 'http://example.com'
          nil # mocked return value
        end
        post_as admin, :create, params: {
          course: {
            name: 'CSC207',
            display_name: 'Software Design',
            is_hidden: true,
            autotest_url: 'http://example.com'
          }
        }
      end
    end

    describe '#edit' do
      it 'responds with 200' do
        get_as admin, :edit, params: { id: course.id }
        expect(response).to have_http_status(:ok)
      end
    end

    describe '#update' do
      let(:params) do
        {
          id: course.id,
          course: {
            display_name: 'Computational Thinking',
            is_hidden: true,
            max_file_size: 200
          }
        }
      end
      let(:invalid_params) do
        {
          id: course.id,
          course: {
            name: 'CSC2000',
            display_name: nil,
            is_hidden: nil,
            max_file_size: nil
          }
        }
      end

      it 'responds with 302' do
        put_as admin, :update, params: params
        expect(response).to have_http_status(:found)
      end

      it 'updates the course' do
        put_as admin, :update, params: params
        updated_course = Course.find(course.id)
        expected_course_data = {
          name: course.name,
          display_name: 'Computational Thinking',
          is_hidden: true,
          max_file_size: 200
        }
        updated_course_data = {
          name: updated_course.name,
          display_name: updated_course.display_name,
          is_hidden: updated_course.is_hidden,
          max_file_size: 200
        }
        expect(updated_course_data).to eq(expected_course_data)
      end

      it 'does not update the course name' do
        put_as admin, :update, params: { id: course.id, course: { name: 'CSC2000' } }
        updated_course = Course.find(course.id)
        expect(updated_course.name).not_to eq('CSC2000')
      end

      context 'updating the autotest_url' do
        it 'does update the autotest_url as an admin' do
          expect(AutotestResetUrlJob).to receive(:perform_later) do |course_, url|
            expect(course_).to eq course
            expect(url).to eq 'http://example.com'
            nil # mocked return value
          end
          put_as admin, :update, params: { id: course.id, course: { autotest_url: 'http://example.com' } }
        end
      end

      it 'does not update when parameters are invalid' do
        expected_course_data = {
          name: course.name,
          display_name: course.display_name,
          is_hidden: course.is_hidden,
          max_file_size: course.max_file_size
        }
        put_as admin, :update, params: invalid_params
        updated_course = Course.find(course.id)
        updated_course_data = {
          name: updated_course.name,
          display_name: updated_course.display_name,
          is_hidden: updated_course.is_hidden,
          max_file_size: updated_course.max_file_size
        }
        expect(updated_course_data).to eq(expected_course_data)
      end
    end

    shared_context 'course with an autotest setting' do
      before do
        allow_any_instance_of(AutotestSetting).to receive(:register).and_return('someapikey')
        allow_any_instance_of(AutotestSetting).to receive(:get_schema).and_return('{}')
      end

      let(:autotest_setting) { create(:autotest_setting) }
      let(:course) { create(:course, autotest_setting: autotest_setting) }
    end

    describe '#test_autotest_connection' do
      subject { get_as admin, :test_autotest_connection, params: { id: course.id } }

      context 'there is no autotest_setting set' do
        it 'should return unprocessable_entity' do
          subject
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'there is an autotest_setting' do
        include_context 'course with an autotest setting'
        it 'should try to get the schema from the autotester' do
          expect(controller).to receive(:get_schema)
          subject
        end

        context 'when the schema is successfully retrieved' do
          before { allow(controller).to receive(:get_schema) }

          it 'should flash a success message' do
            subject
            expect(flash.now[:success]).not_to be_empty
          end
        end

        context 'when the request goes through but the schema is not valid json' do
          before { allow(controller).to receive(:get_schema).and_raise(JSON::ParserError) }

          it 'should flash a success message' do
            subject
            expect(flash.now[:error]).not_to be_empty
          end
        end

        context 'when the request does not go through' do
          before { allow(controller).to receive(:get_schema).and_raise(StandardError) }

          it 'should flash a success message' do
            subject
            expect(flash.now[:error]).not_to be_empty
          end
        end
      end
    end

    describe '#reset_autotest_connection' do
      subject { put_as admin, :reset_autotest_connection, params: { id: course.id } }

      context 'there is no autotest_setting set' do
        it 'should return unprocessable_entity' do
          subject
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'there is an autotest_setting' do
        include_context 'course with an autotest setting'
        it 'should call AutotestResetUrlJob with the correct settings' do
          expect(AutotestResetUrlJob).to receive(:perform_later) do |course_, url, _markus_url, options|
            expect(course_.id).to eq course.id
            expect(url).to eq course.autotest_setting.url
            expect(options[:refresh]).to be_truthy
            OpenStruct.new job_id: 1 # mock return value so that the job id can be set on the session
          end
          subject
        end
      end
    end
  end
end
