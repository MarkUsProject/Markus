class NotificationMailer < ApplicationMailer
  default from: 'noreply@markus.com'
  def release_email
    @user = params[:user]
    @grouping = params[:grouping]
    attachments.inline['markus_logo_big.png'] = File.read(Rails.root.join('app',
                                                                          'assets',
                                                                          'images',
                                                                          'markus_logo_big.png'))
    mail(to: @user.email, subject: default_i18n_subject(course: Rails.configuration.course_name,
                                                        assignment: @grouping.assignment.short_identifier ))
  end
end
