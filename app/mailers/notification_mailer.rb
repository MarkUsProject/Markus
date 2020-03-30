# MarkUs mailer for notifications.
class NotificationMailer < ApplicationMailer
  default from: 'noreply@markus.com'
  def release_email
    @user = params[:user]
    @grouping = params[:grouping]
    mail(to: @user.email, subject: default_i18n_subject(course: Rails.configuration.course_name,
                                                        assignment: @grouping.assignment.short_identifier))
  end

  def release_spreadsheet_email
    @form = params[:form]
    @student = params[:student]
    mail(to: @student.user.email, subject: default_i18n_subject(course: Rails.configuration.course_name,
                                                                form: @form.short_identifier))
  end

  def grouping_invite_email
    @inviter = params[:inviter]
    @invited = params[:invited]
    @grouping = params[:grouping]
    mail(to: @invited.email, subject: default_i18n_subject(course: Rails.configuration.course_name))
  end
end
