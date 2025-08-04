describe MainController do
  include SessionHandler

  let(:student) { create(:student) }
  let(:ta) { create(:ta) }
  let(:instructor) { create(:instructor) }
  let(:instructor2) { create(:instructor) }
  let(:admin_user) { create(:admin_user) }

  context 'A non-authenticated user' do
    it 'should not be able to login with a blank username' do
      post :login, params: { user_login: '', user_password: 'a' }
      expect(flash[:error]).to have_message(I18n.t('main.username_not_blank'))
    end

    it 'should not be able to login with a blank password' do
      post :login, params: { user_login: 'a', user_password: '' }
      expect(flash[:error]).to have_message(I18n.t('main.password_not_blank'))
    end

    describe 'login_remote_auth' do
      before do
        get :login_remote_auth
      end

      it 'should set the auth_type to remote' do
        expect(session[:auth_type]).to eq 'remote'
      end

      it 'should redirect to the remote login page' do
        expect(response).to redirect_to(Settings.remote_auth_login_url)
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

    context 'after logging in without remote user auth' do
      before do
        sign_in instructor
      end

      it 'should not display any errors' do
        expect(flash[:error]).to be_nil
      end

      it 'should set the session real_user to the correct user' do
        expect(real_user&.user_name).to eq(instructor.user_name)
      end

      it 'should start the session timeout counter' do
        expect(session[:timeout]).not_to be_nil
      end

      it 'should redirect the login route to the courses index route' do
        get :login
        expect(response).to redirect_to action: 'index', controller: 'courses'
      end
    end

    context 'after logging in with remote user auth' do
      let(:user_name) { instructor.user_name }

      before do
        allow(self).to receive(:reset_session)
        clear_session
        env_hash = { HTTP_X_FORWARDED_USER: user_name }
        request.headers.merge! env_hash
        session[:auth_type] = 'remote'
      end

      it 'should set the session real_user to the correct user' do
        expect(real_user&.user_name).to eq(instructor.user_name)
      end

      it 'should redirect the login route to the courses index route' do
        get :login
        expect(response).to redirect_to action: 'index', controller: 'courses'
      end

      context 'when MarkUs is in restricted mode' do
        before do
          allow(Settings).to receive_messages(remote_validate_file: Rails.root
                                                     .join('spec/fixtures/files/dummy_remote_validate.sh'),
                                              validate_ip: true)
          allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return('192.168.0.1')
        end

        it 'should return an error if user ip is not in the approved ip range' do
          get :login
          expect(flash[:error].size).to be 1
        end

        context 'with an allowed ip' do
          before do
            allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return('0.0.0.0')
          end

          it 'should redirect to the courses index route' do
            get :login
            expect(response).to redirect_to action: 'index', controller: 'courses'
          end
        end
      end

      context 'going to a page that requires authentication' do
        before { post :logout }

        it 'should respond with redirect' do
          expect(response).to have_http_status(:redirect)
        end

        it 'should not start the session timeout counter' do
          expect(session[:timeout]).to be_nil
        end
      end

      context 'when there is no user with the given user_name' do
        let(:user_name) { build(:end_user).user_name }

        it 'should redirect to the login page' do
          post :logout
          expect(response).to redirect_to action: 'login', controller: 'main'
        end

        it 'should flash an error message when going to login' do
          get :login
          expect(flash[:error]).not_to be_empty
        end

        it 'should flash an error message when going a non-login page' do
          post :logout
          expect(flash[:error]).not_to be_empty
        end
      end
    end

    context 'after logging in with a bad username' do
      it 'should not be able to login with an incorrect username' do
        post :login, params: { user_login: instructor.user_name + 'BAD', user_password: 'a' }
        expect(flash[:error]).to have_message(I18n.t('main.login_failed'))
      end
    end

    context 'logging in during an LTI launch' do
      let(:lti) { create(:lti_deployment) }

      before do
        cookies.encrypted.permanent[:lti_data] = JSON.generate({ lti_redirect: redirect_login_canvas_path })
      end

      it 'redirects to redirect_login' do
        sign_in instructor
        expect(response).to redirect_to action: 'redirect_login', controller: 'canvas'
      end

      context 'when logged in during lti launch' do
        let(:lti) { create(:lti_deployment) }

        before do
          sign_in instructor
          cookies.encrypted.permanent[:lti_data] = JSON.generate({ lti_redirect: redirect_login_canvas_path })
        end

        it 'redirects to course picker if lti data is present' do
          get :login
          expect(response).to have_http_status(:found)
        end
      end
    end

    context 'after logging out' do
      before do
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
      before do
        sign_in student
      end

      it_behaves_like 'student tests'
    end

    context 'after logging in with remote user auth' do
      before do
        env_hash = { HTTP_X_FORWARDED_USER: student.user_name }
        request.headers.merge! env_hash
        sign_in student
      end

      it_behaves_like 'student tests'
    end
  end

  context 'A TA' do
    shared_examples 'ta tests' do
      it 'should redirect to the courses controller' do
        expect(response).to redirect_to controller: 'courses', action: 'index'
      end
    end

    context 'after logging in without remote user auth' do
      before do
        sign_in ta
      end

      it_behaves_like 'ta tests'
    end

    context 'after logging in with remote user auth' do
      before do
        env_hash = { HTTP_X_FORWARDED_USER: ta.user_name }
        request.headers.merge! env_hash
        sign_in ta
      end

      it_behaves_like 'ta tests'
    end
  end

  context 'An Admin User' do
    shared_examples 'admin tests' do
      it 'redirects to the main_admin controller' do
        expect(response).to redirect_to(admin_path)
      end
    end

    context 'after logging in without remote user auth' do
      before do
        sign_in admin_user
      end

      it_behaves_like 'admin tests'
    end

    context 'after logging in with remote user auth' do
      before do
        env_hash = { HTTP_X_FORWARDED_USER: admin_user.user_name }
        request.headers.merge! env_hash
        sign_in admin_user
      end

      it_behaves_like 'admin tests'
    end
  end

  context 'when role switched' do
    let(:course1) { create(:course) }
    let(:course2) { create(:course) }
    let(:instructor) { create(:instructor, course_id: course1.id) }
    let(:instructor2) { create(:instructor, course_id: course2.id) }
    let(:student) { create(:student, course_id: course1.id) }

    before do
      @controller = CoursesController.new
      post_as instructor, :switch_role, params: { id: course1.id, effective_user_login: student.user_name }
    end

    it 'redirects the login route to the course homepage' do
      @controller = MainController.new
      get :login
      expect(response).to redirect_to course_assignments_path(session[:role_switch_course_id])
    end

    it 'flashes a forbidden error message on attempt to access another course' do
      @controller = CoursesController.new
      get :show, params: { id: course2.id }
      expect(flash[:error]).not_to be_empty
    end

    it 'redirects to the original course on attempt to access another course' do
      @controller = CoursesController.new
      get :show, params: { id: course2.id }
      expect(response).to redirect_to course_assignments_path(session[:role_switch_course_id])
    end

    context 'when user tries to log out' do
      before do
        @controller = MainController.new
        get :logout
      end

      it 'should unset the session real_user_name' do
        expect(session[:real_user_name]).to be_nil
      end

      it 'should unset the timeout counter' do
        expect(session[:timeout]).to be_nil
      end

      it 'should unset the session user_name' do
        expect(session[:user_name]).to be_nil
      end

      it 'should unset the session role_switch_course_id' do
        expect(session[:role_switch_course_id]).to be_nil
      end

      it 'should redirect all routes to the login page' do
        get :about
        expect(response).to redirect_to action: 'login', controller: 'main'
      end
    end

    it 'allows user to properly access about' do
      @controller = MainController.new
      request.headers['accept'] = 'text/javascript'
      get :about, xhr: true
      expect(response).to have_http_status(:ok)
    end
  end
end
