describe Admin::UsersController do
  context 'A user with unauthorized access' do
    shared_examples 'cannot access user admin routes' do
      describe '#index' do
        it 'responds with 403' do
          get_as user, :index, format: 'json'
          expect(response).to have_http_status(403)
        end
      end
    end

    context 'Instructor' do
      let(:user) { create(:instructor) }
      include_examples 'cannot access user admin routes'
    end

    context 'TA' do
      let(:user) { create(:ta) }
      include_examples 'cannot access user admin routes'
    end

    context 'Student' do
      let(:user) { create(:student) }
      include_examples 'cannot access user admin routes'
    end
  end

  context 'An admin user managing users' do
    let(:admin) { create(:admin_user) }
    let(:user) { create(:end_user) }

    describe '#index' do
      let!(:autotest_user) { create(:autotest_user) }
      context 'when sending html' do
        it 'responds with 200' do
          get_as admin, :index, format: 'html'
          expect(response).to have_http_status(200)
        end
      end

      context 'when sending json' do
        it 'responds with 200' do
          get_as admin, :index, format: 'json'
          expect(response).to have_http_status(200)
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
          received_data = JSON.parse(response.body).map(&:symbolize_keys)
          expect(received_data).to match_array(expected_data)
        end
      end
    end
  end
end
