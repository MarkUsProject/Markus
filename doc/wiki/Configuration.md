# Configuration Settings

_new in version 1.12.0_

Custom configuration settings for MarkUs can be set by adding a `config/settings.local.yml` file.
Values in this file are described below and will override any default values.


#### Default Values

To show the default values for your environment, run the following command in the root directory of the installed MarkUs instance:

```sh
echo 'puts JSON.parse(Settings.to_json).to_yaml' | bundle exec rails console
```

#### Settings

All values under the `rails:` key are used to set the `Rails.configuration` object when the app starts.

For example, the `queue_adapter` option sets `Rails.configuration.queue_adapter`, and `asset_host` sets `Rails.configuration.action_mailer.asset_host`. For full details see [Rails Guides](https://guides.rubyonrails.org/configuring.html)

```yaml
rails:
  time_zone: # time zone string (supported by ActiveSupport::TimeZone)
  active_job:
    queue_adapter: # queue adapter name (supported by ActiveJob::QueueAdapters)
  assets:
    prefix: # relative path from the rails root to write compiled assets to
  active_record:
    verbose_query_logs: # boolean indicating whether to write verbose query logs
  session_store:
    type: # session store name (supported by ActionDispatch::Session)
    args: # hash of arguments used to initialize the session store class (this may vary by type)
  action_mailer:
    delivery_method: # action mailer delivery method (supported by ActionMailer::Base)
    default_url_options:
      host: # mail server host
    asset_host: # mail asset host
    perform_deliveries: # boolean indicating whether to send mail or not
    deliver_later_queue_name: # name of queue used to send mail as a background job
    sendmail_settings: (required if delivery_method == sendmail) hash containing sendmail settings
    smtp_settings: (required if delivery_method == smtp) hash containing smtp settings
    file_settings: (required if delivery_method == file) hash containing file settings
  cache_classes: # boolean indicating whether classes should be reloaded if they change
  eager_load: # boolean indicating whether to eager load namespaces
  consider_all_requests_local: # boolean indicating whether to display detailed debugging information on an error
  hosts: # (optional) list of hosts to allow when checking for Host header attacks (if empty, no checks are made)
  log_level: # log level
  force_ssl: # boolean indicating that all traffic must be sent over ssl
  active_support:
    deprecation: # string indicating where to write deprecation warnings
  cache_store: # cache store name
  action_controller:
     perform_caching: boolean indicating whether to enable fragment caching (enable this for production only)
queues:
  default: # name of the queue to use as default for background jobs (see "Additional Queue Names" below)
redis:
  url: # url of a running redis service
course_name: # the name of the course using this MarkUs instance
validate_file: # absolute path to the validation script used to validate users on login
validate_ip: # boolean indicating whether to pass the user's ip address to the validation script
validate_custom_exit_status: # custom exit status returned by the validation script
validate_custom_status_message: # message to display to the user if the validation script returns the custom exit status
remote_user_auth: # see "Remote User Authorization" below
logout_redirect: # url to redirect to when a user logs out of MarkUs, 'DEFAULT' will redirect to the login page, 'NONE' will redirect to a 404 page.
repository:
  type: # repository type used to store student submissions. Choose from 'git', 'svn', 'mem'
  url: # (required if type == git or svn) base url used to remotely access a repository over http/https
  ssh_url: # (required if type == git and enable_key_storage == true) base url used to remotely access a repository over ssh
  is_repository_admin: # boolean indicating whether MarkUs manages repositories
  storage: # absolute path to the directory where repositories are stored
max_file_size: # maximum file size (in bytes) allowed to be uploaded through the web interface
student_session_timeout: # duration of a student user's session (in seconds)
ta_session_timeout: # duration of a grader user's session (in seconds)
admin_session_timeout: # duration of an admin user's session (in seconds)
enable_key_storage: # boolean indicating whether to allow ssh public key uploads
key_storage: # absolute path to a directory to store ssh public key uploads
student_csv_upload_order: # column order of student csv upload file (choices are: user_name, last_name, first_name, section_name, id_number, email)
ta_csv_upload_order: # column order of grader csv upload file (choices are: user_name, last_name, first_name, email)
logging:
  enabled: # boolean indicating whether to enable logging
  rotate_by_interval: # boolean whether to rotate logs
  rotate_interval: # (required if rotate_by_interval == true) interval used to rotate logs (choose from: daily, weekly, monthly)
  size_threshold: # (required if rotate_by_interval == false) maximum file size (in bytes) of a single log file
  old_files: # maximum number of log files to keep (older files will be deleted)
  log_file: # relative path (from the MarkUs root) to the log file
  error_file: # relative path (from the MarkUs root) to the error log file
autotest:
  enable: # boolean to indicate whether to enable autotests
  student_test_buffer_minutes: # maximum number of minutes between student tests (see "Student Tests" below)
  url: # url of the autotester API
  client_dir: # absolute path to a directory to store local autotesting files
  max_batch_size: # maximum number of tests to send to the markus-autotesting server in a single batch
scanned_exams:
  enable: # boolean indicating whether to enable scanned exams
  path: # absolute path to a directory to store scanned exam files
i18n:
  available_locales: # list of locale strings (choose from: en, es, pt, fr) (Note that en is the only option that is fully supported)
  default_locale: # locale string to use as default (must be one of the options in available_locales)
validate_user_not_allowed_message: # custom message to display to users who fail validation on login
incorrect_login_message: # custom message to display to users who enter an incorrect username
starter_file:
  storage: # absolute path to a directory to store starter files
python:
   bin: # location of the bin subdirectory of the python3 virtual environment where python dependencies are installed
pandoc: # path to the pandoc executable
```

#### Additional queue names

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

#### Remote User Authorization

If the `remote_user_auth:` setting is false, MarkUs will attempt to validate a user by passing their user_name and password (and optionally their IP address) to the provided validation script and parsing the exit status of that script.

If the `remote_user_auth:` setting is true, MarkUs assumes that users have already been authenticated and will use the user name supplied by `request.env['HTTP_X_FORWARDED_USER']` to log in.

Note that in development mode, if the `remote_user_auth:` setting is false and `request.env['HTTP_X_FORWARDED_USER']` is not set then [`authenticate_or_request_with_http_basic`](https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Basic/ControllerMethods.html#method-i-authenticate_or_request_with_http_basic) will be used to perform authentication (any password is valid in this case).

#### Student Tests

Students are only allowed to run one test at a time. This means that a student must wait until the results from a previous test have returned before they can run another one. If a test result never returns (because of an unexpected error) a student will have to wait `student_test_buffer_minutes` before they can run a new test.

#### Environment variables

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
