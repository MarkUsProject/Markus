require 'rails_helper'

describe 'logging in', type: :system do
  let!(:user) { create :end_user }
  let(:click_login) do
    visit '/'
    click_link(I18n.t('main.login_with', name: Settings.local_auth_login_name ||
      I18n.t('main.local_authentication_default_name')), href: nil)
    fill_in('user_login', with: 'Invalid User', id: 'user_login')
    fill_in('user_password', with: 'x', id: 'user_password')
    click_button(I18n.t('main.log_in'), name: 'commit')
  end

  before do
    driven_by(:rack_test)
  end

  it 'fails to sign in an unknown user' do
    click_login
    expect(page).to have_content(I18n.t('main.login_failed'))
  end

  it 'signs user in' do
    click_login
    expect(page).to have_current_path('/courses')
  end
end
