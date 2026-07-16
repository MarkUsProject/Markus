---
permalink: /administrators/configuration/
title: Configuration
nav_order: 3
parent: Administrators
---
# Configuration Settings
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

*new in version 1.12.0*: Custom configuration settings for MarkUs can be set by adding a `config/settings.local.yml` file.
Values in this file are described below and will override any default values in the `config/settings.yml` or the environment specific files in `config/settings`.

## Default Values

To show the default values for your environment, run the following command in the root directory of the installed MarkUs instance:

```sh
echo 'puts JSON.parse(Settings.to_json).to_yaml' | NO_SCHEMA_VALIDATE=1 NO_INIT_SCHEDULER=1 bundle exec rails console
```

By specifying `NO_SCHEMA_VALIDATE` an error will not be raised if a required key is missing.
By specifying `NO_INIT_SCHEDULER` an error will not be raised if MarkUs can't connect to a redis instance (not required for this task).

## Settings

### Rails Specific Settings

All values under the `rails:` key are used to set the `Rails.configuration` object when the app starts.

For example, the `queue_adapter` option sets `Rails.configuration.queue_adapter`, and `asset_host` sets `Rails.configuration.action_mailer.asset_host`. For full details see [Rails Guides](https://guides.rubyonrails.org/configuring.html)

The default values for these should be good enough for most applications.

```yaml
rails:
  time_zone: # time zone string (supported by ActiveSupport::TimeZone)
  cache_classes: # boolean indicating whether classes should be reloaded if they change
  eager_load: # boolean indicating whether to eager load namespaces
  consider_all_requests_local: # boolean indicating whether to display detailed debugging information on an error
  hosts: # (optional) list of hosts to allow when checking for Host header attacks (if empty, no checks are made)
  force_ssl: # boolean indicating that all traffic must be sent over ssl
  log_level: # log level (one of: debug info warn error fatal unknown)
  cache_store: # cache store name (redis_cache_store is recommended because MarkUs already uses redis elsewhere)
  active_job:
    queue_adapter: # queue adapter name (supported by ActiveJob::QueueAdapters) (resque is recommended because MarkUs already uses redis elsewhere)
  assets:
    prefix: # relative path from the rails root to write compiled assets to
  active_record:
    verbose_query_logs: # boolean indicating whether to write verbose query logs
  session_store:
    type: # session store name (supported by ActionDispatch::Session)
    args: # hash of arguments used to initialize the session store class (this may vary by type. See ActionDispatch::Session documentation for details)
  action_mailer:
    delivery_method: # action mailer delivery method (supported by ActionMailer::Base)
    default_url_options:
      host: # mail server host
    asset_host: # mail asset host
    perform_deliveries: # boolean indicating whether to send mail or not
    deliver_later_queue_name: # name of queue used to send mail as a background job
    sendmail_settings: # (required if delivery_method == sendmail) hash containing sendmail settings
    smtp_settings: # (required if delivery_method == smtp) hash containing smtp settings
    file_settings: # (required if delivery_method == file) hash containing file settings
  active_support:
    deprecation: # string indicating where to write deprecation warnings (See ActiveSupport::Deprecation::Behavior for details)
  action_controller:
     perform_caching: # boolean indicating whether to enable fragment caching (enable this for production only)
  action_cable:
     web_socket_allowed_request_origins: # list of hosts to allow websocket upgrades from. Override in settings/production.yml
```

### Puma settings

[Puma](https://github.com/puma/puma) is an http server for ruby and the default http server used by Rails applications (like MarkUs). MarkUs allows for some configuration of the puma processes through this file with the following settings:

```yaml
puma:
  workers: # the number of worker processes (if this value is more than zero, puma with run in "cluster mode")
  min_threads: # the minimum number of threads per worker process
  max_threads: # the maximum number of threads per worker process
  worker_timeout: # the amount of time in seconds that a puma worker can sit idle before it is restarted, (this cannot be set below 6 seconds)
```

### MarkUs settings

```yaml
queues:
  default: # name of the queue to use as default for background jobs (see "Additional Queue Names" below)
redis:
  url: # url of a running redis database
validate_file: # (See "User Authentication Options" below)
remote_validate_file: # (See "User Authentication Options" below)
validate_ip: # (See "User Authentication Options" below)
validate_custom_status_message: # (See "User Authentication Options" below)
validate_user_not_allowed_message: # (See "User Authentication Options" below)
incorrect_login_message: # (See "User Authentication Options" below)
remote_auth_login_url: # (See "User Authentication Options" below)
remote_auth_login_name: # (See "User Authentication Options" below)
local_auth_login_name: # (See "User Authentication Options" below)
logout_redirect: # (See "User Authentication Options" below)
student_csv_order: # column order of student csv upload file (choices are: user_name, last_name, first_name, section_name, id_number, email)
jupyter_server:
  hosts: # list of host names of servers running jupyterhub that are allowed to connect to this instance of MarkUs
repository:
  type: # repository type used to store student submissions. Choose from 'git', 'mem'. 'git' is preferred since 'mem' is not persistant and should only be used for testing.
  url: # base url used to remotely access a repository over http/https
  ssh_url: # (required if enable_key_storage == true) base url used to remotely access a repository over ssh
  is_repository_admin: # boolean indicating whether MarkUs manages repositories
  markus_git_shell: # (required if type == git and enable_key_storage == true) absolute path to the markus-git-shell.sh script (can be found in lib/repo/) on the ssh server (see the Installation page for more details).
session_timeout: # duration of a user's session (in seconds). This setting is ignored if users log in with remote user authentication (See "User Authentication Options" below for more details)
enable_key_storage: # boolean indicating whether to allow ssh public key uploads (see the Installation page for more details).
logging:
  enabled: # boolean indicating whether to enable logging
  rotate_by_interval: # boolean whether to rotate logs
  rotate_interval: # (required if rotate_by_interval == true) interval used to rotate logs (choose from: daily, weekly, monthly)
  size_threshold: # (required if rotate_by_interval == false) maximum file size (in bytes) of a single log file
  old_files: # maximum number of log files to keep (older files will be deleted)
  log_file: # relative path (from the MarkUs root) to the log file
  error_file: # relative path (from the MarkUs root) to the error log file
  tag_with_usernames: # boolean indicating whether to tag each request written to the logs with the user_name of the user who made the request (note: this requires that rails.session_store.type == 'cookie_store')
scanned_exams:
  enable: # boolean indicating whether to enable scanned exams
resque_scheduler: # configuration for scheduling background jobs (this section can be omitted entirely)
autotest:
  student_test_buffer_minutes: # maximum number of minutes between student tests (see "Student Tests" below)
  max_batch_size: # maximum number of tests to send to the markus-autotesting server in a single batch
i18n:
  available_locales: # list of locale strings (Note that 'en' is the only option that is supported)
  default_locale: # locale string to use as default (must be one of the options in available_locales)
python: # location of a python executable where python dependencies are installed (optional)
rails_performance:
  enabled: # boolean whether to enable the rails performance dashboard (See the "Admin Guide" page for more information about this dashboard)
  duration: # duration in minutes for rails performance to store data for monitoring
exception_notification:
  enabled: # boolean indicating whether to enable email notifactions when errors occur (See "Error Notification Emails" below for more details)
  sender: # email address string with which to email error notifications
  sender_display_name: # sender display name for recipients to see
  email_prefix: # string text to prefix to the error subject line that summarizes the error
  recipients: # list of string email addresses who will recieve error notification emails
file_storage:
  default_root_path: # absolute path to a directory where MarkUs can write and store files
  scanned_exams: # (optional) absolute path to a directory where MarkUs can store scanned exam files (if null, a subdirectory under the default_root_path will be used)
  starter_files: # (optional) absolute path to a directory where MarkUs can store starter files (if null, a subdirectory under the default_root_path will be used)
  autotest: # (optional) absolute path to a directory where MarkUs can store autotest files (if null, a subdirectory under the default_root_path will be used)
  lti: # (optional) absolute path to a directory where MarkUs can store lti key files (if null, a subdirectory under the default_root_path will be used)
  repos: # (optional) absolute path to a directory where MarkUs can store repositories (if null, a subdirectory under the default_root_path will be used)
```

## Additional queue names

By default, background jobs will be run using the queue specified by the

```yaml
queue:
  default:
```

setting. If you would like to use different queue names for different background jobs, you can specify additional keys (the background job name written in snake case) under the `queue:` key.

For example, the following conifguration:

```yaml
queue:
  default: default
  autotest_specs_job: specs_queue
  split_pdf_job: some_other_one
```

Will run all background jobs using a queue named "default" except for `AutotestSpectsJob` which will use a queue named "specs_queue" and `SplitPdfJob` which will use a queue named "some_other_one".

## Scheduled background jobs

MarkUs uses the [resque-scheduler gem](https://github.com/resque/resque-scheduler) to schedule background jobs. The configuration is nested under the settings key `resque_scheduler`, and can be omitted entirely.

We recommend scheduling the `CleanTmpJob` to regularly clean the MarkUs `tmp/` folder. Here is a sample configuration:

```yaml
resque_scheduler:
  CleanTmpJob:
    class: ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper
    queue: DEFAULT_QUEUE
    every: 2d  # run every two days
    # never: "* * * * * *"  # replace every: with never: if you want to run the job manually
    args:
      job_class:  CleanTmpJob
      arguments:
        - 5184000  # 60 days, in seconds; see CleanTmpJob documentation for details
```

## Student Tests

Students are only allowed to run one test at a time. This means that a student must wait until the results from a previous test have returned before they can run another one. If a test result never returns (because of an unexpected error) a student will instead have to wait `student_test_buffer_minutes` before they can run a new test.

## User Authentication Options

When a user logs in to MarkUs they can be authenticated in one of two ways:

1. Local authentication: their username, password, and (optionally) their IP address are sent to the stdin pipe of a script file on disk. If that script exits with a 0, the user is authenticated.
2. Remote authentication: some other service (such as a Single Sign-on provider) authenticates the user's user name and password for MarkUs. If the user is authenticated by this service, the user's user name should be sent in the request header as the value of the "HTTP_X_FORWARDED_USER" key (see Installation instructions for more details).

Once a user is authenticated, using one of the two methods above, MarkUs will check if there is a user with the given user name in the database. If so, the user will be logged in.

MarkUs can be set up to use only one of the authentication options or both depending on which settings are enabled:

**To enable local authentication, set the following settings:**

- `validate_file:` an absolute path to a script that expects input from stdin (user name, password, and IP address; separated by "\n") and returns 0 if the user is authenticated and any other positive integer otherwise.
- `validate_ip:` a boolean value indicating whether MarkUs should send the IP address of the current user to stdin of the validate_file script. If false, only the user name and password will be sent.
- `validate_user_not_allowed_message:` a message to display to users when the validate_file script returns 0 (they are authenticated) but there is no user with the given user name in the MarkUs database. If this is not set, a generic "Login failed" message will be shown.
- `local_auth_login_name:` when a user visits the login page, they will see a button that says "Login with MarkUs authentication". This variable customizes this message. For example the button will read "Login with My super secret method" if the setting is:

```yaml
local_auth_login_name: My super secret method
```

- `validate_custom_status_message:` a hash containing exit statuses (integers) as keys and user facing messages (strings) as values. This allows you to choose what message is displayed to your users depending on the exit status returned by the validate_file script. For example, lets say your validate_file script checks if a user name contains whitespace characters and warns the user if so, you could have the following in your settings:

```yaml
validate_custom_status_message:
  "7": "User names cannot contain whitespace"
```

**To enable remote authentication, set the following settings:**

- `remote_auth_login_url:` The url of a remote authentication service. MarkUs will redirect the user to this URL when logging in and the service should redirect the user back on a successful login (depending on the behaviour of the specific service).
- `remote_auth_login_name:` when a user visits the login page, they will see a button that says "Login with remote authentication". This variable customizes this message. For example the button will read "Login with shibboleth" if the setting is:

```yaml
local_auth_login_name: shibboleth
```

Additionally, MarkUs can be set to restrict remote logins based on username and/or IP when using remote authentication.

**To enable restricted remote authentication, set the following setting:**

- `remote_validate_file:` an absolute path to a script that expects input from stdin (user name, password (blank), and IP address; separated by "\n") and returns 0 if the user is authenticated and any other positive integer otherwise.

### Logout redirect

The `logout_redirect` setting determines where the user will be redirected when they logout of MarkUs. It can be one of `DEFAULT`, `NONE`, or a URL.

- `DEFAULT`: the user will be redirected to MarkUs' login page
- `NONE`: MarkUs will render a 404 error page
- URL: MarkUs will redirect the user to this URL

## Environment variables

All of the settings described above can also be set using environment variables. Environment variables start with `MARKUS__` followed by each nested yaml key separated by `__`. For example,

```sh
MARKUS__REDIS__URL=redis://localhost:6379/1
```

is equivalent to setting this in a yml file:

```yaml
redis:
  url: 'redis://localhost:6379/1'
```

Any setting set by an environment variable will override a setting set in a yml file.

One setting option can only be changed by an environment variable. To set the relative url root for your MarkUs instance, you must set the `RAILS_RELATIVE_URL_ROOT` environment variable. For example, if your relative url root is `/csc108` then you can start the rails server as:

```sh
RAILS_RELATIVE_URL_ROOT=/csc108 bundle exec rails server
```

## Error Notification Emails

If you wish to be informed when a user encounters a server error whilst using MarkUs, you can configure MarkUs to send you an email whenever such an error event happens along with its details. To do so, under the `exception_notification` settings, set the `enabled` setting to true. Be sure to then specify a `sender` email address and a list of `recipients` addresses. You can also optionally set a `sender_display_name` and an `email_prefix`.

Note that in order for this feature to work, you **must** have ActionMailer [configured](https://guides.rubyonrails.org/action_mailer_basics.html) to send emails. This means that you must select an ActionMailer `delivery_method` with the appropriate settings and you must also set `perform_deliveries` to true. You will be unable to send or recieve error notification emails otherwise.

This feature informs you of all uncaught exceptions that occur in the MarkUs backend. In order to possibly avoid filling recipient inboxes with a lot of the same error notifications, email notifications are sent after every `2**n` occurences of the same error. For more details, visit the [exception notification](https://github.com/smartinez87/exception_notification) gem homepage with which we use to provide you this feature.

## LTI Settings

>**Note**: LTI routes are not enabled in production by default. To enable them, you must edit `routes.rb` file.

If you wish to use Learning Tools Interoperability (LTI) with MarkUs, you'll need to configure the LTI settings as follows

- `lti.domains` must be a whitelist of all hosts you expect to receive LTI launches from.
- `lti.token_endpoint` must be the url used to generate an LTI credentials token for the external platform.
- `lti.sync_schedule` must be a cron schedule dictating when MarkUs should attempt to automatically sync its roster via LTI.

You must also create a private key for generating Javascript Web Tokens to sign LTI requests.
A private key can be automatically created with the `markus:lti_key` rake task.

If you wish to filter course creation requests from LTI deployments, add the following keys:

- `lti.course_filter_file` must be the absolute path to a Ruby file that defines a method `LtiConfig::allowed_to_create_course?(lti_deployment)`, which takes an `LtiDeployment` model instance and returns `true` or `false`.
- `lti.unpermitted_new_course_message` must be a message to display if an LTI deployment is rejected by the filter. The message must be a string with interpolation key `%{course_name}`, which will be bound to the `title` field in the launch claim `https://purl.imsglobal.org/spec/lti/claim/context`.
    - Example: `"You are not permitted to create a new MarkUs course for %{course_name}. Please contact your system administrator."`

## Optional Features

### Preview RMarkdown Files as HTML

To preview RMarkdown (.Rmd) submission files as rendered HTML instead of displaying the raw RMarkdown source, enable the following setting:

```yaml
rmd_convert_enabled: true
```
