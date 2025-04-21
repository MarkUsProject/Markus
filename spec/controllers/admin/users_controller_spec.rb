describe Admin::UsersController do
  context 'A user with unauthorized access' do
    shared_examples 'cannot access user admin routes' do
      describe '#index' do
        it 'responds with 403' do
          get_as user, :index, format: 'json'
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#new' do
        it 'responds with 403' do
          get_as user, :new
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#create' do
        let(:params) do
          {
            user: {
              user_name: 'Professor X',
              email: 'sample@sample.com',
              id_number: 100_678_901,
              type: 'EndUser',
              first_name: 'Charles',
              last_name: 'Xavier'
            }
          }
        end

        it 'responds with 403' do
          put_as user, :create, params: params
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#edit' do
        it 'responds with 403' do
          get_as user, :edit, params: { id: user.user.id }
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#update' do
        let(:params) do
          {
            id: user.user.id,
            end_user: {
              user_name: 'Professor X',
              email: 'sample@sample.com',
              id_number: 100_678_901,
              type: 'EndUser',
              first_name: 'Charles',
              last_name: 'Xavier'
            }
          }
        end

        it 'responds with 403' do
          put_as user, :update, params: params
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#upload' do
        it 'responds with 403' do
          post_as user,
                  :upload,
                  params: { upload_file: fixture_file_upload('admin/users_good.csv', 'text/csv') }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'Instructor' do
      let(:user) { create(:instructor) }

      it_behaves_like 'cannot access user admin routes'
    end

    context 'TA' do
      let(:user) { create(:ta) }

      it_behaves_like 'cannot access user admin routes'
    end

    context 'Student' do
      let(:user) { create(:student) }

      it_behaves_like 'cannot access user admin routes'
    end
  end

  context 'An admin user managing users' do
    let(:admin) { create(:admin_user) }
    let(:user) { create(:end_user) }

    describe '#index' do
      before { create(:autotest_user) }

      context 'when sending html' do
        it 'responds with 200' do
          get_as admin, :index, format: 'html'
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when sending json' do
        it 'responds with 200' do
          get_as admin, :index, format: 'json'
          expect(response).to have_http_status(:ok)
        end

        it 'sends the appropriate data' do
          expected_data = [
            {
              id: admin.id,
              user_name: admin.user_name,
              email: admin.email,
              id_number: admin.id_number,
              type: admin.type,
              first_name: admin.first_name,
              last_name: admin.last_name
            },
            {
              id: user.id,
              user_name: user.user_name,
              email: user.email,
              id_number: user.id_number,
              type: user.type,
              first_name: user.first_name,
              last_name: user.last_name
            }
          ]
          get_as admin, :index, format: 'json'
          received_data = response.parsed_body.map(&:symbolize_keys)
          expect(received_data).to match_array(expected_data)
        end
      end
    end

    describe '#new' do
      it 'responds with 200' do
        get_as admin, :new
        expect(response).to have_http_status(:ok)
      end
    end

    describe '#create' do
      let(:params) do
        {
          user: {
            user_name: 'Spiderman',
            email: 'sample@sample.com',
            id_number: 1_122_018,
            type: 'EndUser',
            first_name: 'Miles',
            last_name: 'Morales'
          }
        }
      end
      let(:invalid_non_type_params) do
        {
          user: {
            user_name: 'notValidUser',
            email: 'sample@sample.com',
            id_number: 100_678_901,
            type: 'AdminUser',
            first_name: nil,
            last_name: ''
          }
        }
      end
      let(:params_with_invalid_type) do
        {
          user: {
            user_name: 'Spiderman',
            email: 'sample@sample.com',
            id_number: 1_122_018,
            type: 'Not a real type',
            first_name: 'Miles',
            last_name: 'Morales'
          }
        }
      end

      it 'responds with 302' do
        post_as admin, :create, params: params
        expect(response).to have_http_status(:found)
      end

      it 'creates the user when information is valid' do
        post_as admin, :create, params: params
        created_user = User.find_by(user_name: 'Spiderman')
        expected_user_data = {
          user_name: 'Spiderman',
          email: 'sample@sample.com',
          id_number: '1122018',
          type: 'EndUser',
          first_name: 'Miles',
          last_name: 'Morales'
        }
        created_user_data = {
          user_name: created_user.user_name,
          email: created_user.email,
          id_number: created_user.id_number,
          type: created_user.type,
          first_name: created_user.first_name,
          last_name: created_user.last_name
        }
        expect(expected_user_data).to eq(created_user_data)
      end

      it 'does not create the user when non type related information is invalid' do
        post_as admin, :create, params: invalid_non_type_params
        created_user = User.find_by(user_name: 'notValidUser')
        expect(created_user).to be_nil
      end

      it 'does not create the user when type related information is invalid' do
        post_as admin, :create, params: params_with_invalid_type
        created_user = User.find_by(user_name: 'Spiderman')
        expect(created_user).to be_nil
      end
    end

    describe '#edit' do
      it 'responds with 200' do
        get_as admin, :edit, params: { id: user.id }
        expect(response).to have_http_status(:ok)
      end
    end

    describe '#update' do
      let(:params) do
        {
          id: user.id,
          end_user: {
            user_name: 'Spiderman',
            email: 'sample@sample.com',
            id_number: 1_122_018,
            type: 'AdminUser',
            first_name: 'Miles',
            last_name: 'Morales'
          }
        }
      end
      let(:invalid_params) do
        {
          id: user.id,
          end_user: {
            user_name: nil,
            email: 'sample@sample.com',
            id_number: 100_678_901,
            type: 'Not a real type',
            first_name: '',
            last_name: ''
          }
        }
      end

      it 'responds with 302' do
        put_as admin, :update, params: params
        expect(response).to have_http_status(:found)
      end

      it 'updates the user with valid data' do
        put_as admin, :update, params: params
        updated_user = User.find(user.id)
        expected_user_data = {
          user_name: 'Spiderman',
          email: 'sample@sample.com',
          id_number: '1122018',
          type: 'EndUser',
          first_name: 'Miles',
          last_name: 'Morales'
        }
        updated_user_data = {
          user_name: updated_user.user_name,
          email: updated_user.email,
          id_number: updated_user.id_number,
          type: updated_user.type,
          first_name: updated_user.first_name,
          last_name: updated_user.last_name
        }
        expect(expected_user_data).to eq(updated_user_data)
      end

      it 'does not update when parameters are invalid' do
        expected_user_data = {
          user_name: user.user_name,
          email: user.email,
          id_number: user.id_number,
          type: user.type,
          first_name: user.first_name,
          last_name: user.last_name
        }
        put_as admin, :update, params: invalid_params
        updated_user = User.find(user.id)
        updated_user_data = {
          user_name: updated_user.user_name,
          email: updated_user.email,
          id_number: updated_user.id_number,
          type: updated_user.type,
          first_name: updated_user.first_name,
          last_name: updated_user.last_name
        }
        expect(expected_user_data).to eq(updated_user_data)
      end
    end

    describe '#upload' do
      it_behaves_like 'a controller supporting upload', formats: [:csv], background: true, uploader: :admin_user do
        let(:params) { {} }
      end

      ['.csv', '', '.pdf'].each do |extension|
        ext_string = extension.empty? ? 'none' : extension
        it "calls perform_later on a background job on a valid CSV file with extension '#{ext_string}'" do
          expect(UploadUsersJob).to receive(:perform_later).and_return OpenStruct.new(job_id: 1)
          post_as admin,
                  :upload,
                  params: { upload_file: fixture_file_upload("admin/users_good#{extension}", 'text/csv') }
        end
      end
    end
  end
end
