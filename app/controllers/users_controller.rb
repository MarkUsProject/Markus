# Users controller used to handle universal "Settings" page for all users
class UsersController < ApplicationController
  before_action { authorize! }

  layout 'assignment_content'

  responders :flash, :collection

  def settings; end
  
  def reset_api_key
    @current_user.reset_api_key
  end

  def update_settings
    student = current_user
    student.update!(settings_params)
    update_success
  end

  private

  def update_success
    flash_message(:success, t('users.verify_settings_update'))
    redirect_to action: 'settings'
  end

  def settings_params
    params.require(:student).permit(:receives_invite_emails, :receives_results_emails, :display_name)
  end

  protected

  def implicit_authorization_target
    OpenStruct.new policy_class: UserPolicy
  end
end
