describe Api::SectionsController do
  let(:section) { create :section }
  let(:instructor) { create :instructor }
  let(:course) { section.course }
  context 'An authenticated user requesting' do
    before :each do
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
    end
    context 'POST create' do
      it 'should create a new section when given the correct params' do
        post :create, params: { course_id: course.id, section: { name: 'LEC0301' } }
        expect(response).to have_http_status(201)
        expect(Section.find_by(name: 'LEC0301').name).to eq('LEC0301')
      end

      it 'should throw a 422 error with when given an invalid param' do
        post :create, params: { course_id: course.id, section: { name: '' } }
        expect(response).to have_http_status(422)
      end
    end
  end
end
