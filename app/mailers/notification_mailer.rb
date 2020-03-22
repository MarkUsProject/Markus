# MarkUs mailer for notifications.
class NotificationMailer < ApplicationMailer
  default from: 'noreply@markus.com'
  def release_email
    @user = params[:user]
    @grouping = params[:grouping]
    mail(to: @user.email, subject: default_i18n_subject(course: Rails.configuration.course_name,
                                                        assignment: @grouping.assignment.short_identifier))
  end
end
