# Users controller used to handle universal "Settings" page for all users
class UsersController < ApplicationController
  before_action { authorize! }

  layout 'assignment_content'

  responders :flash, :collection

  def settings; end

  def update_mailer_settings
    student = current_user
    new_settings = params[:student]
    student.update!(receives_results_emails: new_settings[:receives_results_emails],
                    receives_invite_emails: new_settings[:receives_invite_emails])
    update_success
  end

  private

  def update_success
    flash_message(:success, t('users.verify_settings_update'))
    redirect_to action: 'settings'
  end

  protected

  def implicit_authorization_target
    OpenStruct.new policy_class: UserPolicy
  end
end
