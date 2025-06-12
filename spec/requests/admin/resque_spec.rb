describe 'Resque dashboard authorization' do
  context 'when the user is not authenticated' do
    it 'returns a 403 status code' do
      get '/admin/resque'
      expect(response).to have_http_status :forbidden
    end
  end

  context 'when the user is authenticated' do
    before do
      post '/', params: { user_login: user.user_name, user_password: 'a' }
    end

    context 'and is an admin' do
      let(:user) { create(:admin_user) }

      it 'returns a 200 status code' do
        get '/admin/resque'
        expect(response).to have_http_status :redirect
        expect(response).to redirect_to('/admin/resque/overview')
      end

      it 'returns a 403 status code' do
        host! 'unauthorized_host'
        get '/admin/resque'
        expect(response).to have_http_status :forbidden
      end
    end

    context 'and is an instructor' do
      let(:user) { create(:instructor) }

      it 'returns a 200 status code' do
        get '/admin/resque'
        expect(response).to have_http_status :forbidden
      end
    end

    context 'and is a TA' do
      let(:user) { create(:ta) }

      it 'returns a 200 status code' do
        get '/admin/resque'
        expect(response).to have_http_status :forbidden
      end
    end

    context 'and is a student' do
      let(:user) { create(:student) }

      it 'returns a 200 status code' do
        get '/admin/resque'
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
