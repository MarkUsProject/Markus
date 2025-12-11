describe Api::UsersController do
  let(:user) { create(:admin_user) }
  let(:end_users) { create_list(:end_user, 3) }

  context 'An unauthenticated request' do
    before do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: user.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a POST create request' do
      post :create
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update request' do
      put :update, params: { id: user.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update_by_username request' do
      put :update_by_username
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'an authenticated user' do
    before do
      user.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{user.api_key.strip}"
    end

    describe '#index' do
      context 'an admin user' do
        context 'expecting an xml response' do
          before do
            request.env['HTTP_ACCEPT'] = 'application/xml'
            end_users
          end

          it 'should be successful' do
            get :index
            expect(response).to have_http_status(:ok)
          end

          it 'should return info about all the users' do
            get :index
            user_names = Hash.from_xml(response.body).dig('users', 'user').pluck('user_name')
            expect(user_names).to match_array(User.pluck(:user_name))
          end

          it 'should return info about a single user if a filter is used' do
            get :index, params: { filter: { user_name: end_users[0].user_name } }
            user_names = Hash.from_xml(response.body).dig('users', 'user')['user_name']
            expect(user_names).to eq(end_users[0].user_name)
          end

          it 'should return all information in the default fields' do
            get :index
            info = Hash.from_xml(response.body).dig('users', 'user')[0]
            expect(Set.new(info.keys.map(&:to_sym))).to eq Set.new(Api::UsersController::DEFAULT_FIELDS)
          end
        end

        context 'expecting an json response' do
          before do
            request.env['HTTP_ACCEPT'] = 'application/json'
            end_users
          end

          it 'should be successful' do
            get :index
            expect(response).to have_http_status(:ok)
          end

          it 'should return info about all the users' do
            get :index
            expect(response.parsed_body.pluck('user_name')).to match_array(User.pluck(:user_name))
          end

          it 'should return info about a single user if a filter is used' do
            get :index, params: { filter: { user_name: end_users[0].user_name } }
            expect(response.parsed_body.pluck('user_name')).to eq([end_users[0].user_name])
          end

          it 'should return all information in the default fields' do
            get :index
            info = response.parsed_body[0]
            expect(Set.new(info.keys.map(&:to_sym))).to eq Set.new(Api::UsersController::DEFAULT_FIELDS)
          end
        end
      end

      context 'a non-admin user' do
        let(:user) { create(:end_user) }

        it 'should render 403' do
          get :index, format: :json
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe '#show' do
      context 'an admin user' do
        context 'expecting an xml response' do
          before do
            request.env['HTTP_ACCEPT'] = 'application/xml'
            end_users
          end

          it 'should be successful' do
            get :show, params: { id: end_users[0].id }
            expect(response).to have_http_status(:ok)
          end

          it 'should return info about the user' do
            get :show, params: { id: end_users[0].id }
            expect(Hash.from_xml(response.body)['user']['user_name']).to eq(end_users[0].user_name)
          end

          it 'should return all information in the default fields' do
            get :show, params: { id: end_users[0].id }
            info = Hash.from_xml(response.body)['user']
            expect(Set.new(info.keys.map(&:to_sym))).to eq Set.new(Api::UsersController::DEFAULT_FIELDS)
          end
        end

        context 'expecting an json response' do
          before do
            request.env['HTTP_ACCEPT'] = 'application/json'
          end

          it 'should be successful' do
            get :show, params: { id: end_users[0].id }
            expect(response).to have_http_status(:ok)
          end

          it 'should return info about the user' do
            get :show, params: { id: end_users[0].id }
            expect(response.parsed_body['user_name']).to eq(end_users[0].user_name)
          end

          it 'should return all information in the default fields' do
            get :show, params: { id: end_users[0].id }
            info = response.parsed_body
            expect(Set.new(info.keys.map(&:to_sym))).to eq Set.new(Api::UsersController::DEFAULT_FIELDS)
          end
        end
      end

      context 'a non-admin user' do
        let(:user) { create(:end_user) }

        it 'should render 403' do
          get :show, params: { id: end_users[0].id }, format: :json
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe '#create' do
      context 'an admin user' do
        before do
          post :create, params: { user_name: new_user.user_name, type: new_user.type,
                                  first_name: new_user.first_name, last_name: new_user.last_name }
        end

        context 'when creating a new end user' do
          let(:new_user) { build(:end_user) }

          it 'should be successful' do
            expect(response).to have_http_status(:created)
          end

          it 'should create a new user' do
            expect(User.find_by(user_name: new_user.user_name)).not_to be_nil
          end
        end

        context 'when creating a new admin user' do
          let(:new_user) { build(:admin_user) }

          it 'should be successful' do
            expect(response).to have_http_status(:created)
          end

          it 'should create a new user' do
            expect(User.find_by(user_name: new_user.user_name)).not_to be_nil
          end
        end

        context 'when trying to create a user who already exists' do
          let(:new_user) { create(:end_user) }

          it 'should raise a 422 error' do
            expect(response).to have_http_status(:conflict)
          end
        end

        context 'when creating a user with an invalid user_name' do
          let(:new_user) { build(:end_user, user_name: '   dragon ..') }

          it 'should raise a 422 error' do
            expect(response).to have_http_status(:unprocessable_content)
          end
        end

        context 'when creating a user with an invalid type' do
          let(:new_user) { build(:end_user, type: 'Dragon') }

          it 'should raise a 422 error' do
            expect(response).to have_http_status(:unprocessable_content)
          end
        end
      end

      context 'a non-admin user' do
        let(:user) { create(:end_user) }

        it 'should render 403' do
          post :create, format: :json
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe '#update' do
      context 'an admin user' do
        let(:end_user) { create(:end_user) }
        let(:tmp_user) { build(:end_user) }

        context 'when updating an existing user' do
          it 'should update a user name' do
            put :update, params: { id: end_user.id, user_name: tmp_user.user_name }
            expect(response).to have_http_status(:ok)
            end_user.reload
            expect(end_user.user_name).to eq(tmp_user.user_name)
          end

          it 'should update a first name' do
            put :update, params: { id: end_user.id, first_name: tmp_user.first_name }
            expect(response).to have_http_status(:ok)
            end_user.reload
            expect(end_user.first_name).to eq(tmp_user.first_name)
          end

          it 'should update a last name' do
            put :update, params: { id: end_user.id, last_name: tmp_user.last_name }
            expect(response).to have_http_status(:ok)
            end_user.reload
            expect(end_user.last_name).to eq(tmp_user.last_name)
          end
        end
      end

      context 'a non-admin user' do
        let(:user) { create(:end_user) }

        it 'should render 403' do
          put :update, params: { id: end_users[0].id }, format: :json
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe '#update_by_username' do
      context 'an admin user' do
        let(:end_user) { create(:end_user) }
        let(:tmp_user) { build(:end_user) }

        context 'when updating an existing user' do
          it 'should update a first name' do
            put :update_by_username, params: { user_name: end_user.user_name, first_name: tmp_user.first_name }
            expect(response).to have_http_status(:ok)
            end_user.reload
            expect(end_user.first_name).to eq(tmp_user.first_name)
          end

          it 'should update a last name' do
            put :update_by_username, params: { user_name: end_user.user_name, last_name: tmp_user.last_name }
            expect(response).to have_http_status(:ok)
            end_user.reload
            expect(end_user.last_name).to eq(tmp_user.last_name)
          end
        end
      end

      context 'a non-admin user' do
        let(:user) { create(:end_user) }

        it 'should render 403' do
          put :update_by_username, params: { id: end_users[0].id }, format: :json
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
