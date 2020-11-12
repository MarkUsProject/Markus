describe UsersController do
  let(:admin) { create :admin }

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
  end

  describe 'User is a Student' do
    include ERB::Util
    RSpec.shared_examples 'changing particular mailer settings' do
      it 'can be enabled in settings' do
        student.update!(setting => false)
        patch_as student,
                 'update_settings',
                 params: { student: { setting => true, other_setting => true } }
        student.reload
        expect(student[setting]).to be true
      end

      it 'can be disabled in settings' do
        student.update!(setting => true)
        patch_as student,
                 'update_settings',
                 params: { student: { setting => false, other_setting => true } }
        student.reload
        expect(student[setting]).to be false
      end
    end

    describe 'results released notifications' do
      # Authenticate user is not timed out, and is a student.
      let(:setting) { 'receives_results_emails' }
      let(:other_setting) { 'receives_invite_emails' }
      let(:student) { create(:student, user_name: 'c6stenha') }

      include_examples 'changing particular mailer settings'
    end

    describe 'group invite notifications' do
      # Authenticate user is not timed out, and is a student.
      let(:setting) { 'receives_invite_emails' }
      let(:other_setting) { 'receives_results_emails' }
      let(:student) { create(:student, user_name: 'c6stenha') }

      include_examples 'changing particular mailer settings'
    end

    describe 'changing any setting' do
      let(:student) { create(:student, user_name: 'c6stenha') }
      it 'redirects back to settings' do
        patch_as student,
                 'update_settings',
                 params: { 'student': { 'receives_invite_emails': false, 'receives_results_emails': true } }
        expect(response).to redirect_to(settings_users_path)
      end
    end

    describe 'change display name in settings' do
      let(:student) { create(:student, user_name: 'c6stenha') }
      it 'updates student display_name' do
        display_name = 'First Last'
        patch_as student,
                 'update_settings',
                 params: { 'student': { 'display_name': display_name } }
        expect(student.reload.display_name).to eq display_name
      end
    end
    
    describe '#reset_api_key' do
      let(:student) { create(:student) }
      it 'cannot reset their api key' do
        post_as student, :reset_api_key
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
