describe MainController do
  let(:student) { create :student }
  let(:ta) { create :ta }
  let(:instructor) { create :instructor }
  let(:instructor2) { create :instructor }
  context 'A non-authenticated user' do
    it 'should not be able to login with a blank username' do
      post :login, params: { user_login: '', user_password: 'a' }
      expect(ActionController::Base.helpers.strip_tags(flash[:error][0])).to eq(I18n.t('main.username_not_blank'))
    end
    it 'should not be able to login with a blank password' do
      post :login, params: { user_login: 'a', user_password: '' }
      expect(ActionController::Base.helpers.strip_tags(flash[:error][0])).to eq(I18n.t('main.password_not_blank'))
    end
    describe 'login_remote_auth' do
      before do
        env_hash = { 'HTTP_X_FORWARDED_USER': http_x_forwarded_user }
        request.headers.merge! env_hash
        get :login_remote_auth
      end
      context 'remote user is set' do
        let(:http_x_forwarded_user) { 'a' }
        it 'should set the auth_type to remote' do
          expect(session[:auth_type]).to eq :remote
        end
        it 'should redirect to the main page' do
          expect(response).to redirect_to(main_path)
        end
      end
      context 'remote user is not set' do
        let(:http_x_forwarded_user) { nil }
        it 'should set the auth_type to remote' do
          expect(session[:auth_type]).to eq :remote
        end
        it 'should redirect to the remote login page' do
          expect(response).to redirect_to(Settings.remote_auth_login_url)
        end
      end
    end
  end
  context 'An Instructor' do
    let :all_assignments do
      a2 = create(:assignment, due_date: 1.day.ago)
      a1 = create(:assignment, due_date: 2.days.ago)
      a3 = create(:assignment, due_date: 1.day.from_now)
      [a1, a2, a3]
    end

    shared_examples 'instructor tests' do
      it 'should be able to login' do
        expect(response).to redirect_to controller: 'courses', action: 'index'
      end
      it 'should not display any errors' do
        expect(flash[:error]).to be_nil
      end
      it 'should set the session real_user_name to the correct user' do
        expect(session[:real_user_name]).to eq(instructor.user_name)
      end
      it 'should start the session timeout counter' do
        expect(session[:timeout]).not_to be_nil
      end
      it 'should redirect the login route to the index route' do
        get :login
        expect(response).to redirect_to action: 'index', controller: 'courses'
      end
    end
    context 'after logging in without remote user auth' do
      before(:each) do
        sign_in instructor
      end
      include_examples 'instructor tests'
    end
    context 'after logging in with remote user auth' do
      before :each do
        env_hash = { 'HTTP_X_FORWARDED_USER': instructor.user_name }
        request.headers.merge! env_hash
        sign_in instructor
      end
      include_examples 'instructor tests'
    end
    context 'after logging in with a bad username' do
      it 'should not be able to login with an incorrect username' do
        post :login, params: { user_login: instructor.user_name + 'BAD', user_password: 'a' }
        expect(ActionController::Base.helpers.strip_tags(flash[:error][0])).to eq(I18n.t('main.login_failed'))
      end
    end
    context 'after logging out' do
      before(:each) do
        post :login, params: { user_login: instructor.user_name, user_password: 'a' }
        get :logout
      end
      it 'should unset the session real_user_name' do
        expect(session[:real_user_name]).to be_nil
      end
      it 'should unset the timeout counter' do
        expect(session[:timeout]).to be_nil
      end
      it 'should redirect all routes to the login page' do
        get :about
        expect(response).to redirect_to action: 'login', controller: 'main'
      end
    end
  end
  context 'A student' do
    shared_examples 'student tests' do
      it 'should redirect to the courses controller' do
        expect(response).to redirect_to controller: 'courses', action: 'index'
      end
    end
    context 'after logging in without remote user auth' do
      before(:each) do
        sign_in student
      end
      include_examples 'student tests'
    end
    context 'after logging in with remote user auth' do
      before :each do
        env_hash = { 'HTTP_X_FORWARDED_USER': student.user_name }
        request.headers.merge! env_hash
        sign_in student
      end
      include_examples 'student tests'
    end
  end
  context 'A TA' do
    shared_examples 'ta tests' do
      it 'should redirect to the courses controller' do
        expect(response).to redirect_to controller: 'courses', action: 'index'
      end
    end
    context 'after logging in without remote user auth' do
      before(:each) do
        sign_in ta
      end
      include_examples 'ta tests'
    end
    context 'after logging in with remote user auth' do
      before :each do
        env_hash = { 'HTTP_X_FORWARDED_USER': ta.user_name }
        request.headers.merge! env_hash
        sign_in ta
      end
      include_examples 'ta tests'
    end
  end
end
