class UsersController < ApplicationController
  before_action :authorize_for_user, only: :settings
  before_action :authorize_for_student, only: [:mailer_settings, :update_mailer_settings]

  layout 'assignment_content'

  responders :flash, :collection

  def settings; end
  def mailer_settings; end

  def update_mailer_settings
    student = current_user
    new_settings = params[:student]
    student.update!(receives_results_emails: new_settings[:receives_results_emails],
                    receives_invite_emails: new_settings[:receives_invite_emails])
    flash_message(:success, t('students.verify_settings_update'))
    redirect_to action: 'mailer_settings'
  end
end
