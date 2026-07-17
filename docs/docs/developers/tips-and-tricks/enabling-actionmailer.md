---
permalink: /developers/tips-and-tricks/enabling-actionmailer/
title: Enabling ActionMailer in Development
parent: Tips and Tricks
grand_parent: Developers
nav_order: 1
---
# ActionMailer in MarkUs
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

The Rails ActionMailer is used in MarkUs to send automated emails when grouping submissions are released, grade entry forms are released, and students invite other students to groupings. These calls to the mailer are in the files `submissions_helper.rb`, `grade_entry_forms_controller.rb`, and `groups_controller.rb` respectively. Students opt in to receiving emails by default, but can choose to unsubscribe by changing their preferences through two attributes: `receives_results_emails` and `receives_invite_emails`.

The ActionMailer is also used to send automatic email notifications informing an admin when a user has encountered a server error. For more details about this feature, visit the section on [Error Notification Emails](../../administrators/configuration.md#error-notification-emails) in the Configuration page.

## Configuring ActionMailer for Development

When using the ActionMailer features of MarkUs, the MarkUs administrators configure an email server. For the sake of development, you can configure MarkUs to send emails from a service you already use (such as Gmail, Outlook, etc). Here, we will talk specifically about configuring ActionMailer with a gmail account using the `:smtp` delivery method.

1. Create a file in the `config` folder with the name `settings.local.yml`. This file allows you to configure Rails and/or MarkUs settings specifically for your local MarkUs instance.

    **Note**: This new file will not be tracked by git. Any settings you configure in this file will not (and should not) be committed.

2. Ensure your `config/settings.local.yml` file contains the following settings:

    ```yaml
    rails:
      action_mailer:
          delivery_method: smtp
          default_url_options:
              host: 'localhost:3000'
          asset_host: 'http://localhost:3000'
          perform_deliveries: true
          deliver_later_queue_name: ~
          smtp_settings:
              address: smtp.gmail.com
              port: 587
              user_name: # Your gmail username
              password: # Your created application password. See steps 3-4 for more details
              authentication: plain
              enable_starttls_auto: true
    ```

3. Generate an app password for MarkUs. See the appropriate [Google Help](https://support.google.com/accounts/answer/185833?hl=en) page for instructions on how to do this.
4. Copy and paste the app password into the `password` field under `smtp_settings`.
5. Start the MarkUs server: `docker compose up rails`.

## For Troubleshooting Email Issues

If you have issues with emails not sending due to authentication issues (in particular gmail), you can reference the `Troubleshooting Email Sending Errors` section in [this guide.](https://dev.to/morinoko/sending-emails-in-rails-with-action-mailer-and-gmail-35g4)

In the case that your issue is not solved by that information, head to [the Action Mailer guide.](https://guides.rubyonrails.org/action_mailer_basics.html)
