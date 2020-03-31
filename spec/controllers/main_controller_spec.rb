describe MainController do
  let(:student) { create :student }
  let(:ta) { create :ta }
  let(:admin) { create :admin }
  let(:admin2) { create :admin }
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
      expect(ActionController::Base.helpers.strip_tags(flash[:error][0])).to eq(I18n.t('main.username_not_blank'))
    end
    it 'should not be able to login with a blank password' do
      post :login, params: { user_login: 'a', user_password: '' }
      expect(ActionController::Base.helpers.strip_tags(flash[:error][0])).to eq(I18n.t('main.password_not_blank'))
    end
  end
  context 'An Admin' do
    let :all_assignments do
      a2 = create(:assignment, due_date: 1.day.ago)
      a1 = create(:assignment, due_date: 2.days.ago)
      a3 = create(:assignment, due_date: 1.day.from_now)
      [a1, a2, a3]
    end

    shared_examples 'admin tests' do
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
      context 'while switching roles' do
        before :each do
          allow(Rails.configuration).to receive(:remote_user_auth).and_return(false)
        end
        it 'should not switch roles when switching to themself' do
          post :login_as, params: { effective_user_login: '', user_login: admin.user_name, admin_password: 'a' }
          expect(session[:real_uid]).to be_nil
        end
        it 'should not switch roles when switching to another admin' do
          post :login_as,
               params: { effective_user_login: admin2.user_name, user_login: admin.user_name, admin_password: 'a' }
          expect(session[:real_uid]).to be_nil
        end
        context 'and switching to a student with the correct credentials' do
          before :each do
            post :login_as,
                 params: { effective_user_login: student.user_name, user_login: admin.user_name, admin_password: 'a' }
          end
          it 'should render the _role_switch_handler view' do
            is_expected.to render_template('_role_switch_handler')
          end
          it 'should set the real uid to the admin id' do
            expect(session[:real_uid]).to eq(admin.id)
          end
          it 'should set the uid to the student id' do
            expect(session[:uid]).to eq(student.id)
          end
          context 'and then logging out' do
            before(:each) { post :logout }
            it 'should unset the real uid' do
              expect(session[:real_uid]).to be_nil
            end
            it 'should unset the uid' do
              expect(session[:uid]).to be_nil
            end
          end
        end
        context 'and switching to a ta with the correct credentials' do
          before :each do
            post :login_as,
                 params: { effective_user_login: ta.user_name, user_login: admin.user_name, admin_password: 'a' }
          end
          it 'should set the real uid to the admin id' do
            expect(session[:real_uid]).to eq(admin.id)
          end
          it 'should set the uid to the ta id' do
            expect(session[:uid]).to eq(ta.id)
          end
          context 'and then logging out' do
            before(:each) { post :logout }
            it 'should unset the real uid' do
              expect(session[:real_uid]).to be_nil
            end
            it 'should unset the uid' do
              expect(session[:uid]).to be_nil
            end
          end
        end
      end
    end
    context 'after logging in without remote user auth' do
      before(:each) do
        allow(Rails.configuration).to receive(:remote_user_auth).and_return(false)
        sign_in admin
      end
      include_examples 'admin tests'
      it 'should not switch roles when providing an empty password' do
        post :login_as,
             params: { effective_user_login: student.user_name, user_login: admin.user_name, admin_password: '' }
        expect(session[:real_uid]).to be_nil
      end
    end
    context 'after logging in with remote user auth' do
      before :each do
        allow(Rails.configuration).to receive(:remote_user_auth).and_return(true)
        env_hash = { 'HTTP_X_FORWARDED_USER': admin.user_name }
        request.headers.merge! env_hash
        sign_in admin
      end
      include_examples 'admin tests'
      it 'should switch roles when providing an empty password' do
        post :login_as,
             params: { effective_user_login: student.user_name, user_login: admin.user_name, admin_password: '' }
        expect(session[:real_uid]).to be(admin.id)
      end
    end
    context 'after logging in with a bad username' do
      it 'should not be able to login with an incorrect username' do
        post :login, params: { user_login: admin.user_name+'BAD', user_password: 'a' }
        expect(ActionController::Base.helpers.strip_tags(flash[:error][0])).to eq(I18n.t('main.login_failed'))
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
    shared_examples 'student tests' do
      it 'should redirect to the assignments controller' do
        get :index
        expect(response).to redirect_to controller: 'assignments', action: 'index'
      end
      context 'while switching roles' do
        context 'and trying to log in as an admin' do
          before :each do
            post :login_as,
                 params: { effective_user_login: student.user_name, user_login: admin.user_name, admin_password: 'a' }
          end
          it { is_expected.to respond_with 404 }
          it 'should not change the uid' do
            expect(session[:uid]).to eq(student.id)
          end
          it 'should not set the real_uid' do
            expect(session[:real_uid]).to be_nil
          end
        end
        context 'and trying to log in as a TA' do
          before :each do
            post :login_as,
                 params: { effective_user_login: student.user_name, user_login: ta.user_name, admin_password: 'a' }
          end
          it { is_expected.to respond_with 404 }
          it 'should not change the uid' do
            expect(session[:uid]).to eq(student.id)
          end
          it 'should not set the real_uid' do
            expect(session[:real_uid]).to be_nil
          end
        end
      end
    end
    context 'after logging in without remote user auth' do
      before(:each) do
        allow(Rails.configuration).to receive(:remote_user_auth).and_return(false)
        sign_in student
      end
      include_examples 'student tests'
    end
    context 'after logging in with remote user auth' do
      before :each do
        allow(Rails.configuration).to receive(:remote_user_auth).and_return(true)
        env_hash = { 'HTTP_X_FORWARDED_USER': student.user_name }
        request.headers.merge! env_hash
        sign_in student
      end
      include_examples 'student tests'
    end
  end
  context 'A TA' do
    shared_examples 'ta tests' do
      it 'should redirect to the assignments controller' do
        get :index
        expect(response).to redirect_to controller: 'assignments', action: 'index'
      end
      context 'while switching roles' do
        context 'and trying to log in as an admin' do
          before :each do
            post :login_as,
                 params: { effective_user_login: ta.user_name, user_login: admin.user_name, admin_password: 'a' }
          end
          it { is_expected.to respond_with 404 }
          it 'should not change the uid' do
            expect(session[:uid]).to eq(ta.id)
          end
          it 'should not set the real_uid' do
            expect(session[:real_uid]).to be_nil
          end
        end
        context 'and trying to log in as a student' do
          before :each do
            post :login_as,
                 params: { effective_user_login: ta.user_name, user_login: student.user_name, admin_password: 'a' }
          end
          it { is_expected.to respond_with 404 }
          it 'should not change the uid' do
            expect(session[:uid]).to eq(ta.id)
          end
          it 'should not set the real_uid' do
            expect(session[:real_uid]).to be_nil
          end
        end
      end
    end
    context 'after logging in without remote user auth' do
      before(:each) do
        allow(Rails.configuration).to receive(:remote_user_auth).and_return(false)
        sign_in ta
      end
      include_examples 'ta tests'
    end
    context 'after logging in with remote user auth' do
      before :each do
        allow(Rails.configuration).to receive(:remote_user_auth).and_return(true)
        env_hash = { 'HTTP_X_FORWARDED_USER': ta.user_name }
        request.headers.merge! env_hash
        sign_in ta
      end
      include_examples 'ta tests'
    end
  end
end
