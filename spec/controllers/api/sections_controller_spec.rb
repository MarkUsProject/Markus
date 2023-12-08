describe Api::SectionsController do
  include AutomatedTestsHelper

  let(:section) { create :section }
  let(:course) { section.course }

  context 'An unauthorized attempt' do
    it 'fails to delete section' do
      delete :destroy, params: { course_id: course.id, id: section }
      expect(response).to have_http_status(403)
      expect(Section.exists?(section.id)).to be_truthy
    end
  end

  context 'An authorized attempt' do
    before do
      @instructor = create(:instructor)
    end

    before :each do
      # The following two lines take care of the 'authorization'
      @instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{@instructor.api_key.strip}"
    end

    it 'successfully deletes section' do
      delete :destroy, params: { course_id: course.id, id: section }
      expect(response).to have_http_status(:ok)
      # The below two check the same thing, not sure which is preferable
      expect { Section.find(section.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(Section.exists?(section.id)).to be_falsey
    end
  end
end
