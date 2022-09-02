describe Admin::CoursesController do
  context 'A user with unauthorized access' do
    let(:course) { create(:course) }

    shared_examples 'cannot access admin routes' do
      describe '#index' do
        it 'responds with 403' do
          get_as user, :index, format: 'json'
          expect(response).to have_http_status(403)
        end
      end

      describe '#new' do
        it 'responds with 403' do
          get_as user, :new
          expect(response).to have_http_status(403)
        end
      end

      describe '#create' do
        it 'responds with 403' do
          post_as user, :create,
                  params: { course: { name: 'CS101', display_name: 'Intro to CS', is_hidden: true } }
          expect(response).to have_http_status(403)
        end
      end

      describe '#edit' do
        it 'responds with 403' do
          get_as user, :edit, params: { id: course.id }
          expect(response).to have_http_status(403)
        end
      end

      describe '#update' do
        it 'responds with 403' do
          put_as user, :update,
                 params: { id: course.id, course: { name: 'CS101', display_name: 'Intro to CS', is_hidden: true } }
          expect(response).to have_http_status(403)
        end
      end
    end

    context 'Instructor' do
      let(:user) { create(:instructor, course: course) }
      include_examples 'cannot access admin routes'
    end

    context 'TA' do
      let(:user) { create(:ta, course: course) }
      include_examples 'cannot access admin routes'
    end

    context 'Student' do
      let(:user) { create(:student, course: course) }
      include_examples 'cannot access admin routes'
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
          expect(response).to have_http_status(200)
        end
      end

      context 'when sending json' do
        it 'responds with 200' do
          get_as admin, :index, format: 'json'
          expect(response).to have_http_status(200)
        end
        it 'sends the appropriate data' do
          get_as admin, :index, format: 'json'
          received_data = JSON.parse(response.body).map(&:symbolize_keys)
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
        expect(response).to have_http_status(200)
      end
    end

    describe '#create' do
      before do
        allow_any_instance_of(AutotestSetting).to receive(:register).and_return(1)
        allow_any_instance_of(AutotestSetting).to receive(:get_schema).and_return('{}')
      end
      it 'responds with 302' do
        post_as admin, :create, params: { course: { name: 'CSC207', display_name: 'Software Design', is_hidden: true } }
        expect(response).to have_http_status(302)
      end
      it 'creates the course' do
        post_as admin, :create, params: { course: { name: 'CSC207', display_name: 'Software Design', is_hidden: true } }
        created_course = Course.find_by(name: 'CSC207')
        expected_course_data = {
          name: 'CSC207',
          display_name: 'Software Design',
          is_hidden: true
        }
        created_course_data = {
          name: created_course.name,
          display_name: created_course.display_name,
          is_hidden: created_course.is_hidden
        }
        expect(created_course_data).to eq(expected_course_data)
      end
      it 'does not update when parameters are invalid' do
        post_as admin, :create, params: { course: { name: 'CSC207', display_name: nil, is_hidden: true } }
        created_course = Course.find_by(name: 'CSC207')
        expect(created_course).to be_nil
      end
      it 'updates the autotest_url' do
        post_as admin, :create, params: {
          course: {
            name: 'CSC207',
            display_name: 'Software Design',
            is_hidden: true,
            autotest_url: 'http://example.com'
          }
        }
        expect(Course.find_by(name: 'CSC207').reload.autotest_setting.url).to eq 'http://example.com'
      end
    end

    describe '#edit' do
      it 'responds with 200' do
        get_as admin, :edit, params: { id: course.id }
        expect(response).to have_http_status(200)
      end
    end

    describe '#update' do
      let(:params) do
        {
          id: course.id,
          course: {
            display_name: 'Computational Thinking',
            is_hidden: true
          }
        }
      end
      let(:invalid_params) do
        {
          id: course.id,
          course: {
            name: 'CSC2000',
            display_name: nil,
            is_hidden: nil
          }
        }
      end
      it 'responds with 302' do
        put_as admin, :update, params: params
        expect(response).to have_http_status(302)
      end
      it 'updates the course' do
        put_as admin, :update, params: params
        updated_course = Course.find(course.id)
        expected_course_data = {
          name: course.name,
          display_name: 'Computational Thinking',
          is_hidden: true
        }
        updated_course_data = {
          name: updated_course.name,
          display_name: updated_course.display_name,
          is_hidden: updated_course.is_hidden
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
          is_hidden: course.is_hidden
        }
        put_as admin, :update, params: invalid_params
        updated_course = Course.find(course.id)
        updated_course_data = {
          name: updated_course.name,
          display_name: updated_course.display_name,
          is_hidden: updated_course.is_hidden
        }
        expect(updated_course_data).to eq(expected_course_data)
      end
    end
  end
end
