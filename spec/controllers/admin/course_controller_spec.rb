describe Admin::CoursesController do
  describe '#index' do
    shared_examples 'user with unauthorized access' do
      it 'responds with 403' do
        get_as user, :index, format: 'js'
        expect(response).to have_http_status(403)
      end
    end
    context 'Instructor' do
      let(:user) { create(:instructor) }
      include_examples 'user with unauthorized access'
    end
    context 'TA' do
      let(:user) { create(:ta) }
      include_examples 'user with unauthorized access'
    end
    context 'Student' do
      let(:user) { create(:student) }
      include_examples 'user with unauthorized access'
    end
    context 'Admin' do
      let(:user) { create(:admin_user) }
      it 'responds with 200 when sending javascript' do
        get_as user, :index, format: 'js'
        expect(response).to have_http_status(200)
      end
      it 'responds with 404 when sending html' do
        get_as user, :index, format: 'html'
        expect(response).to have_http_status(404)
      end
    end
  end
end
