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
  end
  context 'An admin user in the course' do
    let(:human) { build :human }
    before :each do
      human.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{human.api_key.strip}"
    end
    context 'with multiple courses as admin' do
      before :each do
        create_list :admin, 4, human: human
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
  end
end
