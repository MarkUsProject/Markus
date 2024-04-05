describe 'Rails Performance dashboard authorization' do
  context 'when the user is not authenticated' do
    it 'returns a 403 status code' do
      get '/admin/rails/performance'
      expect(response).to have_http_status :forbidden
    end
  end

  context 'when the user is authenticated' do
    before do
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).with(:auth_type)
                                                                             .and_return('local')
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).and_call_original
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).with(:real_user_name)
                                                                             .and_return(user.user_name)
      get '/admin/rails/performance'
    end

    context 'and is an admin' do
      let(:user) { create(:admin_user) }

      it 'returns a 200 status code' do
        expect(response).to have_http_status :ok
      end
    end

    context 'and is an instructor' do
      let(:user) { create(:instructor) }

      it 'returns a 403 status code' do
        expect(response).to have_http_status :forbidden
      end
    end

    context 'and is a TA' do
      let(:user) { create(:ta) }

      it 'returns a 403 status code' do
        expect(response).to have_http_status :forbidden
      end
    end

    context 'and is a student' do
      let(:user) { create(:student) }

      it 'returns a 403 status code' do
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
