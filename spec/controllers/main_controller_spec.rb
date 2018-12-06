describe MainController do
  context 'A non-authenticated user' do
    before(:each) { get :index }
    it 'should be redirected to the login page' do
      expect(response).to redirect_to action: 'login', controller: 'main'
    end
    it 'should have no initial errors on the login page' do
      expect(flash[:error]).to be_nil
    end
    it 'should not be able to login with a blank username' do
      post :login, params: { user_login: '', user_password: 'a' }
      expect(flash[:error][0]).to eq(I18n.t(:username_not_blank))
    end
    it 'should not be able to login with a blank password' do
      post :login, params: { user_login: 'a', user_password: '' }
      expect(flash[:error][0]).to eq(I18n.t(:password_not_blank))
    end
  end
  context 'An Admin' do
    let(:admin) { create :admin }
    let :all_assignments do
      a2 = create(:assignment, due_date: 1.day.ago)
      a1 = create(:assignment, due_date: 2.days.ago)
      a3 = create(:assignment, due_date: 1.day.from_now)
      [a1, a2, a3]
    end
    context 'after logging in' do
      before(:each) { post :login, params: { user_login: admin.user_name, user_password: 'a' } }
      it 'should be able to login' do
        expect(response).to redirect_to action: 'index'
      end
      it 'should not display any errors' do
        expect(flash[:error]).to be_nil
      end
      it 'should set the session uid to the correct user' do
        expect(session[:uid]).to eq(admin.id)
      end
      it 'should start the session timeout counter' do
        expect(session[:timeout]).not_to be_nil
      end
      it 'should redirect the login route to the index route' do
        get :login
        expect(response).to redirect_to action: 'index', controller: 'main'
      end
      it 'should be able to reset their api key' do
        post :reset_api_key
        expect(response).to have_http_status(:success)
      end
      it 'should change their api key when it is reset' do
        old_key = admin.api_key
        post :reset_api_key
        admin.reload
        expect(admin.api_key).not_to eq(old_key)
      end
      it 'should not change the api key with a get request' do
        get :reset_api_key
        expect(response).to have_http_status(:not_found)
      end
      it 'should not change the api key with a get request' do
        admin.reload # admin is initialized with a nil api_key and is assigned one on reload
        old_key = admin.api_key
        get :reset_api_key
        admin.reload
        expect(admin.api_key).to eq(old_key)
      end
      it 'should order the assignments in ascending order by due date' do
        get :index
        expect(assigns(:assignments)).to eq(all_assignments)
      end
    end
    context 'after logging in with a bad username' do
      it 'should not be able to login with an incorrect username' do
        post :login, params: { user_login: admin.user_name+'BAD', user_password: 'a' }
        expect(flash[:error][0]).to eq(I18n.t(:login_failed))
      end
    end
    context 'after logging out' do
      before(:each) do
        post :login, params: { user_login: admin.user_name, user_password: 'a' }
        get :logout
      end
      it 'should unset the session uid' do
        expect(session[:uid]).to be_nil
      end
      it 'should unset the timeout counter' do
        expect(session[:timeout]).to be_nil
      end
      it 'should redirect all routes to the login page' do
        get :index
        expect(response).to redirect_to action: 'login', controller: 'main'
      end
    end
  end
  context 'A student' do
    let(:student) { create :student }
    before(:each) { post :login, params: { user_login: student.user_name, user_password: 'a' } }
    context 'after logging in' do
      it 'should redirect to the assignments controller' do
        get :index
        expect(response).to redirect_to controller: 'assignments', action: 'index'
      end
    end
  end
end
