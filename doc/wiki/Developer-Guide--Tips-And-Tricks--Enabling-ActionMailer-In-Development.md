# Action Mailer in MarkUs

The Rails ActionMailer is used in MarkUs to send automated emails when grouping submissions are released, grade entry forms are released, and students invite other students to groupings. These calls to the mailer are in the files `submissions_helper.rb`, `grade_entry_forms_controller.rb`, and `groups_controller.rb` respectively. Students opt in to receiving emails by default, but can choose to unsubscribe by changing their preferences through two attributes: `receives_results_emails` and `receives_invite_emails`.

# Changing the Development Environment

When using the Action Mailer features of MarkUs to send email notifications to students, the MarkUs administrators configure an email server. For the sake of development, you can configure MarkUs to send emails from a service you already use (such as Gmail, Outlook, etc). You can do so by changing the development environment with the `config.action_mailer` values. As an example, consider the case we want to send an email, and we can use our gmail account to do so. We `cd` into the Markus repository and go to `/config/environments/development.rb` and add the following lines after the section on logging (replacing your email and password in the relevant fields indicated).

```
  ###################################################################
  # Email Notifications
  ###################################################################
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
      address:              'smtp.gmail.com',
      port:                 587,
      domain:               'example.com',
      user_name:            '<YOUR_EMAIL>',
      password:             '<YOUR_PASSWORD>',
      authentication:       'plain',
      enable_starttls_auto: true
  }
  config.action_mailer.default_url_options = {host: 'localhost:3000'}
  config.action_mailer.asset_host = 'http://localhost:3000'
  config.action_mailer.perform_deliveries = true
```
**Remember to never commit your email and password.**
# For Troubleshooting Email Issues
If you have issues with emails not sending due to authentication issues (in particular gmail), you can reference the `Troubleshooting Email Sending Errors` section in [this guide.](https://dev.to/morinoko/sending-emails-in-rails-with-action-mailer-and-gmail-35g4)

In the case that your issue is not solved by that information, head to [the Action Mailer guide.](https://guides.rubyonrails.org/action_mailer_basics.html)
