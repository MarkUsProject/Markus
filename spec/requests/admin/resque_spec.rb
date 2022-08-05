describe 'Resque dashboard authorization', type: :request do
  context 'when the user is not authenticated' do
    it 'returns a 403 status code' do
      get '/admin/resque'
      expect(response).to have_http_status :forbidden
    end
  end

  context 'when the user is authenticated and an admin' do
    before do
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).with(:auth_type)
                                                                             .and_return('local')
    end

    context 'and is an admin' do
      let(:user) { create(:admin_user) }
      it 'returns a 200 status code' do
        # TODO: Change this to first login using a POST request, rather than mocking session.
        #   It seems that currently the session isn't persisted across two separate requests.
        allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).with(:real_user_name)
                                                                               .and_return(user.user_name)
        get '/admin/resque'
        expect(response).to have_http_status :redirect
        expect(response).to redirect_to('/admin/resque/overview')
      end
    end

    context 'and is an instructor' do
      let(:user) { create(:instructor) }
      it 'returns a 200 status code' do
        allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).with(:real_user_name)
                                                                               .and_return(user.user_name)
        get '/admin/resque'
        expect(response).to have_http_status :forbidden
      end
    end

    context 'and is a TA' do
      let(:user) { create(:ta) }
      it 'returns a 200 status code' do
        allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).with(:real_user_name)
                                                                               .and_return(user.user_name)
        get '/admin/resque'
        expect(response).to have_http_status :forbidden
      end
    end

    context 'and is a student' do
      let(:user) { create(:student) }
      it 'returns a 200 status code' do
        allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).with(:real_user_name)
                                                                               .and_return(user.user_name)
        get '/admin/resque'
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
