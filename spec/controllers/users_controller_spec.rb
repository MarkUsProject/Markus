describe UsersController do
  let(:admin) { create :admin }

  shared_examples 'change locale' do
    describe 'change locale in settings' do
      before { I18n.locale = :en }

      it 'updates locale' do
        locale = 'es'
        patch_as user, 'update_settings', params: { 'user': { 'locale': locale } }

        expect(user.reload.locale).to eq locale
        expect(I18n.locale).to eq locale.to_sym
      end
    end
  end

  describe 'GET settings' do
    before { get_as admin, :settings }
    it 'should respond with success' do
      is_expected.to respond_with(:success)
    end
    it 'should render settings' do
      expect(response).to render_template(:settings)
    end
  end

  describe 'User is an admin' do
    let(:user) { admin }
    describe '#reset_api_key' do
      it 'responds with a success' do
        post_as admin, :reset_api_key
        expect(response).to have_http_status(:success)
      end
      it 'changes their api key' do
        old_key = admin.api_key
        post_as admin, :reset_api_key
        admin.reload
        expect(admin.api_key).not_to eq(old_key)
      end
    end

    include_examples 'change locale'
  end

  describe 'User is a TA' do
    let(:user) { create :ta }

    describe 'change display name in settings' do
      it 'updates student display_name' do
        display_name = 'First Last'
        patch_as user,
                 'update_settings',
                 params: { 'user': { 'display_name': display_name } }
        expect(user.reload.display_name).to eq display_name
      end
    end

    include_examples 'change locale'
  end

  describe 'User is a Student' do
    include ERB::Util
    let(:user) { create(:student, user_name: 'c6stenha') }
    RSpec.shared_examples 'changing particular mailer settings' do
      it 'can be enabled in settings' do
        user.update!(setting => false)
        patch_as user,
                 'update_settings',
                 params: { user: { setting => true, other_setting => true } }
        user.reload
        expect(user[setting]).to be true
      end

      it 'can be disabled in settings' do
        user.update!(setting => true)
        patch_as user,
                 'update_settings',
                 params: { user: { setting => false, other_setting => true } }
        user.reload
        expect(user[setting]).to be false
      end
    end

    describe 'results released notifications' do
      # Authenticate user is not timed out, and is a student.
      let(:setting) { 'receives_results_emails' }
      let(:other_setting) { 'receives_invite_emails' }

      include_examples 'changing particular mailer settings'
    end

    describe 'group invite notifications' do
      # Authenticate user is not timed out, and is a student.
      let(:setting) { 'receives_invite_emails' }
      let(:other_setting) { 'receives_results_emails' }

      include_examples 'changing particular mailer settings'
    end
    describe 'changing any setting' do
      it 'redirects back to settings' do
        patch_as user,
                 'update_settings',
                 params: { 'user': { 'receives_invite_emails': false, 'receives_results_emails': true } }
        expect(response).to redirect_to(settings_users_path)
      end
    end

    describe 'change display name in settings' do
      it 'updates student display_name' do
        display_name = 'First Last'
        patch_as user,
                 'update_settings',
                 params: { 'user': { 'display_name': display_name } }
        expect(user.reload.display_name).to eq display_name
      end
    end

    describe 'change time zone in settings' do
      it 'updates time zone for student' do
        time_zone = 'Pacific Time (US & Canada)'
        patch_as user,
                 'update_settings',
                 params: { 'user': { 'time_zone': time_zone } }
        expect(user.reload.time_zone).to eq time_zone
      end
    end

    include_examples 'change locale'

    describe '#reset_api_key' do
      it 'cannot reset their api key' do
        post_as user, :reset_api_key
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
