describe Admin::MainAdminController do
  describe '#index' do
    subject { get_as user, :index }
    shared_examples 'user with unauthorized access' do
      it('should respond with 403') do
        subject
        expect(response.status).to eq 403
      end
    end
    context 'Instructor' do
      let(:user) { create(:instructor) }
      shared_examples 'user with unauthorized access'
    end
    context 'TA' do
      let(:user) { create(:ta) }
      shared_examples 'user with unauthorized access'
    end
    context 'Student' do
      let(:user) { create(:student) }
      shared_examples 'user with unauthorized access'
    end
    context 'Admin' do
      let(:user) { create(:admin_user) }
      it('should respond with 200') do
        subject
        expect(response.status).to eq 200
      end
    end
  end
  context 'a non-existent route' do
    it 'should reroute to page_not_found' do
      expect(get: '/admin/badroute').to route_to(controller: 'main', action: 'page_not_found', path: 'admin/badroute')
    end
  end
end
