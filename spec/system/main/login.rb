require 'rails_helper'

describe 'logging in', type: :system do
  before do
    driven_by(:rack_test)
  end

  it 'signs user in' do
    create :end_user
    visit '/'
    click_button I18n.t('main.login_with',
                        name: Settings.local_auth_login_name || I18n.t('main.local_authentication_default_name'))
    within('#session') do
      fill_in '#user_login', with: user.user_name
      fill_in '#user_password', with: 'x'
    end
    click_button I18n.t('main.log_in')
    expect(page).to have_content 'Success'
  end
end
