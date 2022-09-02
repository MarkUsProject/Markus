describe Api::CoursesController do
  let(:course) { create :course }
  context 'An unauthenticated request' do
    before :each do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: course.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a POST create request' do
      get :create
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a PUT update request' do
      get :update, params: { id: course.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a PUT update_autotest_url request' do
      get :update_autotest_url, params: { id: course.id }
      expect(response).to have_http_status(403)
    end
  end
  context 'An instructor user in the course' do
    let(:end_user) { build :end_user }
    before :each do
      end_user.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{end_user.api_key.strip}"
    end
    context 'with multiple courses as instructor' do
      before :each do
        build_list(:instructor, 4, user: end_user) { |instructor| instructor.update(course_id: create(:course).id) }
        get :index
      end
      it 'should be successful' do
        expect(response.status).to eq(200)
      end
      it 'should return xml content' do
        course_ids = Hash.from_xml(response.body).dig('courses', 'course').map { |course| course['id'].to_i }
        expect(course_ids).to contain_exactly(*Course.ids)
      end
      it 'should return all default fields' do
        keys = Hash.from_xml(response.body).dig('courses', 'course').first.keys.map(&:to_sym).sort
        expect(keys).to eq(Api::CoursesController::DEFAULT_FIELDS.sort)
      end
    end
    it 'should fail to authenticate a POST create request' do
      get :create
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a PUT update request' do
      get :update, params: { id: course.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a PUT update_autotest_url request' do
      get :update_autotest_url, params: { id: course.id }
      expect(response).to have_http_status(403)
    end
  end
  context 'an admin user' do
    let(:admin_user) { create :admin_user }
    before :each do
      admin_user.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{admin_user.api_key.strip}"
    end
    context '#create' do
      let(:params) { { name: 'test', display_name: 'test', is_hidden: true } }
      before { get :create, params: params }
      it 'creates a course' do
        expect(Course.first).not_to be_nil
      end
      it 'creates a course with the right attributes' do
        expect(Course.find_by(params)).not_to be_nil
      end
    end
    context '#update' do
      let(:course) { create :course }
      let(:params) { { id: course.id, name: 'test', display_name: 'test', is_hidden: true } }
      before { put :update, params: params }
      it 'updates the course with the right attributes' do
        expect(course.reload.attributes.slice(*params.keys.map(&:to_s))).to eq params.stringify_keys
      end
    end
    context '#update_autotest_url' do
      let(:course) { create :course }
      subject { put :update_autotest_url, params: { id: course.id, url: 'http://example.com' } }
      it 'should call AutotestResetUrlJob' do
        expect(AutotestResetUrlJob).to receive(:perform_now) do |course_, url|
          expect(course_).to eq course
          expect(url).to eq 'http://example.com'
        end
        subject
      end
    end
  end
end
