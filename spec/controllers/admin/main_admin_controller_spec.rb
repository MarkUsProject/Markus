describe Admin::MainAdminController do
  describe '#index' do
    subject { get_as user, :index }

    shared_examples 'user with unauthorized access' do
      it 'responds with 403' do
        subject
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'Instructor' do
      let(:user) { create(:instructor) }

      it_behaves_like 'user with unauthorized access'
    end

    context 'TA' do
      let(:user) { create(:ta) }

      it_behaves_like 'user with unauthorized access'
    end

    context 'Student' do
      let(:user) { create(:student) }

      it_behaves_like 'user with unauthorized access'
    end

    context 'Admin' do
      let(:user) { create(:admin_user) }

      it 'responds with 200' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context 'a non-existent route' do
    it 'reroutes to page_not_found' do
      expect(get: '/admin/badroute').to route_to(controller: 'main', action: 'page_not_found', path: 'admin/badroute')
    end
  end
end
