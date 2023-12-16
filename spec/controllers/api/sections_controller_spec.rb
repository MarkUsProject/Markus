describe Api::SectionsController do
  include AutomatedTestsHelper

  let(:section) { create :section }
  let(:instructor) { create :instructor }
  let(:course) { section.course }

  context 'An unauthorized attempt' do
    it 'fails to delete section' do
      delete :destroy, params: { course_id: course.id, id: section }
      expect(response).to have_http_status(403)
      expect(course.sections.exists?(section.id)).to be_truthy
    end
  end

  context 'An authorized attempt' do
    before :each do
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
    end

    context 'POST create' do
      it 'should create a new section when given the correct params' do
        post :create, params: { course_id: course.id, section: { name: 'LEC0301' } }
        expect(response).to have_http_status(201)
        expect(course.sections.find_by(name: 'LEC0301').name).to eq('LEC0301')
      end

      it 'should throw a 422 error and not create a section with when given an invalid param' do
        post :create, params: { course_id: course.id, section: { name: '' } }
        expect(response).to have_http_status(422)
        expect(course.sections.find_by(name: '')).to be_nil
      end
    end

    context 'Delete' do
      it 'successfully deletes section' do
        delete :destroy, params: { course_id: course.id, id: section }
        expect(response).to have_http_status(:ok)
        expect(course.sections.exists?(section.id)).to be_falsey
      end
    end
  end
end
