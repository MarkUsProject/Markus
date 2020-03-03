class NotificationMailer < ApplicationMailer
  def release_email
    @user = params[:user]
    @grouping = params[:grouping]
    attachments.inline['markus_logo_big.png'] = File.read(Rails.root.join('app', 'assets', 'images', 'markus_logo_big.png'))
    mail(to: @user.email, subject: 'MarkUs Notification (' + Rails.configuration.course_name + ') Your marks for ' + @grouping.assignment.short_identifier + ' have released!')
  end
end
