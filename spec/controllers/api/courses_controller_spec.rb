describe Api::CoursesController do
  let(:course) { create(:course) }

  shared_examples 'Get #index' do |role|
    context 'when expecting xml response' do
      context 'with no courses' do
        it 'should be successful' do
          get :index
          expect(response).to have_http_status(:ok)
        end

        it 'should return empty content' do
          get :index
          expect(Hash.from_xml(response.body)['courses']).to be_nil
        end
      end

      context 'with a single course' do
        before { create(role, user: user, course: course) }

        it 'should be successful' do
          get :index
          expect(response).to have_http_status(:ok)
        end

        it 'should return xml content' do
          get :index
          expect(Hash.from_xml(response.body).dig('courses', 'course', 'id')).to eq(course.id.to_s)
        end

        it 'should return all default fields' do
          get :index
          keys = Hash.from_xml(response.body).dig('courses', 'course').keys.map(&:to_sym)
          expect(keys).to match_array Api::CoursesController::DEFAULT_FIELDS
        end
      end

      context 'with multiple courses' do
        before { create_list(role, 4, user: user) { |r| r.update(course_id: create(:course).id) } }

        it 'should be successful' do
          get :index
          expect(response).to have_http_status(:ok)
        end

        it 'should return xml content' do
          get :index
          course_ids = Hash.from_xml(response.body).dig('courses', 'course').map { |course| course['id'].to_i }
          expect(course_ids).to match_array(user.courses.ids)
        end

        it 'should return all default fields' do
          get :index
          keys = Hash.from_xml(response.body).dig('courses', 'course').first.keys.map(&:to_sym)
          keys.sort!
          expect(keys).to eq(Api::CoursesController::DEFAULT_FIELDS.sort)
        end
      end
    end

    context 'expecting a json response' do
      before do
        request.env['HTTP_ACCEPT'] = 'application/json'
      end

      context 'with no courses' do
        it 'should be successful' do
          get :index
          expect(response).to have_http_status(:ok)
        end

        it 'should return empty content' do
          get :index
          expect(response.parsed_body).to be_empty
        end
      end

      context 'with a single course' do
        before { create(role, user: user, course: course) }

        it 'should be successful' do
          get :index
          expect(response).to have_http_status(:ok)
        end

        it 'should return json content' do
          get :index
          expect(response.parsed_body&.first&.dig('id')).to eq(course.id)
        end

        it 'should return all default fields' do
          get :index
          keys = response.parsed_body&.first&.keys&.map(&:to_sym)
          expect(keys).to match_array Api::CoursesController::DEFAULT_FIELDS
        end
      end

      context 'with multiple courses' do
        before { create_list(role, 4, user: user) { |r| r.update(course_id: create(:course).id) } }

        it 'should be successful' do
          get :index
          expect(response).to have_http_status(:ok)
        end

        it 'should return json content' do
          get :index
          expect(response.parsed_body.length).to eq(*user.courses.ids.count)
        end

        it 'should return all default fields' do
          get :index
          keys = response.parsed_body.map { |h| h.keys.map(&:to_sym) }
          expect(keys).to all(match_array(Api::CoursesController::DEFAULT_FIELDS))
        end
      end
    end
  end

  context 'An unauthenticated request' do
    before do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a POST create request' do
      get :create
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update request' do
      get :update, params: { id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update_autotest_url request' do
      get :update_autotest_url, params: { id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a GET test_autotest_connection request' do
      get :test_autotest_connection, params: { id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT reset_autotest_connection request' do
      put :reset_autotest_connection, params: { id: course.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'An instructor user in the course' do
    let!(:user) { build(:end_user) }

    before do
      user.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{user.api_key.strip}"
    end

    it_behaves_like 'Get #index', :instructor

    describe '#show' do
      let(:start_time) { Time.zone.parse('2026-01-05') }
      let(:end_time) { Time.zone.parse('2026-04-05') }
      let(:course) { create(:course, start_at: start_time, end_at: end_time) }

      before do
        request.env['HTTP_ACCEPT'] = 'application/json'
        create(:instructor, user: user, course: course)
      end

      it 'returns course start_at and end_at dates' do
        get :show, params: { id: course.id }
        expect(response).to have_http_status(:ok)

        expect(Time.zone.parse(response.parsed_body['start_at'])).to be_within(1.second).of(start_time)
        expect(Time.zone.parse(response.parsed_body['end_at'])).to be_within(1.second).of(end_time)
      end
    end

    it 'should fail to authenticate a POST create request' do
      get :create
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update request' do
      get :update, params: { id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update_autotest_url request' do
      get :update_autotest_url, params: { id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not update course start_at/end_at date as an instructor' do
      old_start_at = course.start_at
      old_end_at = course.end_at

      put :update, params: { id: course.id,
                             start_at: Time.zone.parse('2026-01-05'), end_at: Time.zone.parse('2026-04-05') }

      expect(response).to have_http_status(:forbidden)

      course.reload
      expect(course.start_at).to eq(old_start_at)
      expect(course.end_at).to eq(old_end_at)
    end
  end

  context 'An authenticated student request' do
    let(:user) { build(:end_user) }

    before do
      user.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{user.api_key.strip}"
    end

    it_behaves_like 'Get #index', :student

    it 'does not update course start_at/end_at date as a student' do
      old_start_at = course.start_at
      old_end_at = course.end_at

      put :update, params: { id: course.id,
                             start_at: Time.zone.parse('2026-01-05'), end_at: Time.zone.parse('2026-04-05') }

      expect(response).to have_http_status(:forbidden)

      course.reload
      expect(course.start_at).to eq(old_start_at)
      expect(course.end_at).to eq(old_end_at)
    end
  end

  context 'An authenticated TA request' do
    let(:user) { build(:end_user) }

    before do
      user.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{user.api_key.strip}"
    end

    it_behaves_like 'Get #index', :ta

    it 'does not update course start_at/end_at date as a TA' do
      old_start_at = course.start_at
      old_end_at = course.end_at

      put :update, params: { id: course.id,
                             start_at: Time.zone.parse('2026-01-05'), end_at: Time.zone.parse('2026-04-05') }

      expect(response).to have_http_status(:forbidden)

      course.reload
      expect(course.start_at).to eq(old_start_at)
      expect(course.end_at).to eq(old_end_at)
    end
  end

  context 'an admin user' do
    let(:admin_user) { create(:admin_user) }

    before do
      admin_user.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{admin_user.api_key.strip}"
    end

    context 'GET #index' do
      context 'when expecting an xml response' do
        context 'with no courses' do
          it 'should be successful' do
            get :index
            expect(response).to have_http_status(:ok)
          end

          it 'should return empty content' do
            get :index
            expect(Hash.from_xml(response.body)['courses']).to be_nil
          end
        end

        context 'with a single course' do
          let!(:course) { create(:course) }

          it 'should be successful' do
            get :index
            expect(response).to have_http_status(:ok)
          end

          it 'should return xml content' do
            get :index
            expect(Hash.from_xml(response.body).dig('courses', 'course', 'id')).to eq(course.id.to_s)
          end

          it 'should return all default fields' do
            get :index
            keys = Hash.from_xml(response.body).dig('courses', 'course').keys.map(&:to_sym)
            expect(keys).to match_array Api::CoursesController::DEFAULT_FIELDS
          end
        end

        context 'with multiple courses' do
          before { create_list(:course, 4) }

          it 'should be successful' do
            get :index
            expect(response).to have_http_status(:ok)
          end

          it 'should return xml content' do
            get :index
            course_ids = Hash.from_xml(response.body).dig('courses', 'course').map { |course| course['id'].to_i }
            expect(course_ids).to match_array(Course.ids)
          end

          it 'should return all default fields' do
            get :index
            keys = Hash.from_xml(response.body).dig('courses', 'course').first.keys.map(&:to_sym)
            keys.sort!
            expect(keys).to eq(Api::CoursesController::DEFAULT_FIELDS.sort)
          end
        end
      end

      context 'expecting a json response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
        end

        context 'with no courses' do
          it 'should be successful' do
            get :index
            expect(response).to have_http_status(:ok)
          end

          it 'should return empty content' do
            get :index
            expect(response.parsed_body).to be_empty
          end
        end

        context 'with a single course' do
          let!(:course) { create(:course) }

          it 'should be successful' do
            get :index
            expect(response).to have_http_status(:ok)
          end

          it 'should return json content' do
            get :index
            expect(response.parsed_body&.first&.dig('id')).to eq(course.id)
          end

          it 'should return all default fields' do
            get :index
            keys = response.parsed_body&.first&.keys&.map(&:to_sym)
            expect(keys).to match_array Api::CoursesController::DEFAULT_FIELDS
          end
        end

        context 'with multiple courses' do
          before { create_list(:course, 4) }

          it 'should be successful' do
            get :index
            expect(response).to have_http_status(:ok)
          end

          it 'should return json content' do
            get :index
            expect(response.parsed_body.length).to eq(*Course.ids.count)
          end

          it 'should return all default fields' do
            get :index
            keys = response.parsed_body.map { |h| h.keys.map(&:to_sym) }
            expect(keys).to all(match_array(Api::CoursesController::DEFAULT_FIELDS))
          end
        end
      end
    end

    describe '#create' do
      let(:params) { { name: 'test', display_name: 'test', is_hidden: true } }

      before { get :create, params: params }

      it 'creates a course' do
        expect(Course.first).not_to be_nil
      end

      it 'creates a course with the right attributes' do
        expect(Course.find_by(params)).not_to be_nil
      end
    end

    describe '#update' do
      let(:course) { create(:course) }
      let(:start_time) { Time.zone.parse('2026-01-05') }
      let(:end_time) { Time.zone.parse('2026-04-05') }
      let(:params) do
        { id: course.id, name: 'test', display_name: 'test', is_hidden: true, start_at: start_time, end_at: end_time }
      end

      before { put :update, params: params }

      it 'updates the course with the right attributes' do
        expect(course.reload.attributes.slice(*params.keys.map(&:to_s))).to eq params.stringify_keys
      end

      it 'does update course start_at/end_at date as an admin' do
        course.reload
        expect(course.start_at).to be_within(1.second).of(start_time)
        expect(course.end_at).to be_within(1.second).of(end_time)
      end
    end

    describe '#update_autotest_url' do
      subject { put :update_autotest_url, params: { id: course.id, url: 'http://example.com' } }

      let(:course) { create(:course) }

      it 'should call AutotestResetUrlJob' do
        expect(AutotestResetUrlJob).to receive(:perform_now) do |course_, url|
          expect(course_).to eq course
          expect(url).to eq 'http://example.com'
        end
        subject
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
      subject { get :test_autotest_connection, params: { id: course.id } }

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

          it 'should succeed' do
            subject
            expect(response).to have_http_status(:ok)
          end
        end

        context 'when the request goes through but the schema is not valid json' do
          before { allow(controller).to receive(:get_schema).and_raise(JSON::ParserError) }

          it 'should fail' do
            subject
            expect(response).to have_http_status(:internal_server_error)
          end
        end

        context 'when the request does not go through' do
          before { allow(controller).to receive(:get_schema).and_raise(StandardError) }

          it 'should fail' do
            subject
            expect(response).to have_http_status(:internal_server_error)
          end
        end
      end
    end

    describe '#reset_autotest_connection' do
      subject { put :reset_autotest_connection, params: { id: course.id } }

      context 'there is no autotest_setting set' do
        it 'should return unprocessable_entity' do
          subject
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'there is an autotest_setting' do
        include_context 'course with an autotest setting'
        it 'should call AutotestResetUrlJob with the correct settings' do
          expect(AutotestResetUrlJob).to receive(:perform_now) do |course_, url, _markus_url, options|
            expect(course_.id).to eq course.id
            expect(url).to eq course.autotest_setting.url
            expect(options[:refresh]).to be_truthy
          end
          subject
        end

        it 'should succeed when no error is raised' do
          allow(AutotestResetUrlJob).to receive(:perform_now)
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'should fail when an error is raised' do
          allow(AutotestResetUrlJob).to receive(:perform_now).and_raise(StandardError)
          subject
          expect(response).to have_http_status(:internal_server_error)
        end
      end
    end
  end
end
