Config.setup do |config|
  # Name of the constant exposing loaded settings
  config.const_name = 'Settings'

  # Ability to remove elements of the array set in earlier loaded settings file. For example value: '--'.
  #
  # config.knockout_prefix = nil

  # Overwrite an existing value when merging a `nil` value.
  # When set to `false`, the existing value is retained after merge.
  #
  config.merge_nil_values = true

  # Overwrite arrays found in previously loaded settings file. When set to `false`, arrays will be merged.
  #
  # config.overwrite_arrays = true

  # Load environment variables from the `ENV` object and override any settings defined in files.
  #
  config.use_env = true

  # Define ENV variable prefix deciding which variables to load into config.
  #
  # Reading variables from ENV is case-sensitive. If you define lowercase value below, ensure your ENV variables are
  # prefixed in the same way.
  #
  # When not set it defaults to `config.const_name`.
  #
  config.env_prefix = 'MARKUS'

  # What string to use as level separator for settings loaded from ENV variables. Default value of '.' works well
  # with Heroku, but you might want to change it for example for '__' to easy override settings from command line, where
  # using dots in variable names might not be allowed (eg. Bash).
  #
  config.env_separator = '__'

  # Ability to process variables names:
  #   * nil  - no change
  #   * :downcase - convert to lower case
  #
  config.env_converter = :downcase

  # Parse numeric values as integers instead of strings.
  #
  config.env_parse_values = true

  # Validate presence and type of specific config values. Check https://github.com/dry-rb/dry-validation for details.
  unless ENV.fetch('NO_SCHEMA_VALIDATE', false)
    config.schema do
      required(:rails).hash do
        required(:time_zone).value(included_in?: ActiveSupport::TimeZone::MAPPING.keys)
        required(:cache_classes).filled(:bool)
        required(:eager_load).filled(:bool)
        required(:consider_all_requests_local).filled(:bool)
        optional(:hosts).array(:string)
        required(:force_ssl).filled(:bool)
        required(:log_level).filled(included_in?: %w[debug info warn error fatal unknown])
        required(:active_support).hash do
          required(:deprecation).filled(included_in?: ActiveSupport::Deprecation::DEFAULT_BEHAVIORS.keys.map(&:to_s))
        end
        optional(:action_controller).hash do
          optional(:perform_caching).filled(:bool)
          optional(:default_url_options).hash
        end
        optional(:cache_store).filled(:string)
        required(:active_record).hash do
          required(:verbose_query_logs).filled(:bool)
        end
        required(:active_job).hash do
          required(:queue_adapter).filled(:string)
        end
        required(:assets).hash do
          required(:prefix).filled(:string)
        end
        required(:session_store).hash do
          required(:type).filled(:string)
          required(:args).hash do
            optional(:key).filled(:string)
            optional(:path).filled(:string)
            optional(:expire_after).value(:integer, gt?: 0)
            optional(:secure).filled(:bool)
            optional(:same_site).filled(:string)
            optional(:secret).filled(:string)
          end
        end
        required(:action_mailer).hash do
          required(:delivery_method).filled(:string)
          optional(:smtp_settings).hash
          optional(:sendmail_settings).hash
          optional(:file_settings).hash
          required(:default_url_options).hash
          required(:asset_host).filled(:string)
          required(:perform_deliveries).filled(:bool)
          required(:deliver_later_queue_name).maybe(:string)
        end
        optional(:action_cable).hash do
          optional(:web_socket_allowed_request_origins).array(:string)
        end
      end
      required(:puma).hash do
        required(:workers).filled(:integer, gt?: -1)
        required(:min_threads).filled(:integer, gt?: -1)
        required(:max_threads).filled(:integer, gt?: -1)
        required(:worker_timeout).filled(:integer, gt?: 5) # puma enforces a minimum 6 second worker timeout
      end
      required(:jupyter_server).hash do
        required(:hosts).array(:string)
      end
      required(:queues).hash do
        required(:default).filled(:string)
        optional(:autotest_cancel_job).filled(:string)
        optional(:autotest_run_job).filled(:string)
        optional(:autotest_specs_job).filled(:string)
        optional(:create_groups_job).filled(:string)
        optional(:download_submissions_job).filled(:string)
        optional(:generate_job).filled(:string)
        optional(:split_pdf_job).filled(:string)
        optional(:submissions_job).filled(:string)
        optional(:uncollect_submissions_job).filled(:string)
        optional(:update_repo_required_files_job).filled(:string)
        optional(:update_repo_permissions_job).filled(:string)
      end
      required(:redis).hash do
        required(:url).filled(:string)
      end
      optional(:resque_scheduler).hash
      optional(:validate_file).filled(:string)
      optional(:remote_validate_file).filled(:string)
      optional(:validate_ip).filled(:bool)
      required(:validate_custom_status_message).hash
      required(:validate_user_not_allowed_message).maybe(:string)
      required(:incorrect_login_message).maybe(:string)
      optional(:remote_auth_login_url).filled(:string)
      optional(:remote_auth_login_name).filled(:string)
      optional(:local_auth_login_name).filled(:string)
      required(:logout_redirect).filled(:string)
      optional(:student_csv_order).array(
        included_in?: %w[user_name last_name first_name section_name id_number email]
      )
      optional(:end_user_csv_order).array(
        included_in?: %w[user_name last_name first_name id_number email]
      )
      required(:rmd_convert_enabled).filled(:bool)
      required(:repository).hash do
        required(:url).filled(:string)
        optional(:ssh_url).filled(:string)
        required(:is_repository_admin).filled(:bool)
      end
      required(:session_timeout).value(:integer, gt?: 0)
      required(:enable_key_storage).filled(:bool)
      required(:logging).hash do
        required(:enabled).filled(:bool)
        required(:rotate_by_interval).filled(:bool)
        optional(:rotate_interval).filled(included_in?: %w[daily weekly monthly])
        required(:size_threshold).filled(:integer, gt?: 0)
        required(:old_files).filled(:integer, gt?: 0)
        required(:log_file).filled(:string)
        required(:error_file).filled(:string)
        required(:tag_with_usernames).filled(:bool)
      end
      required(:scanned_exams).hash do
        required(:enable).filled(:bool)
      end
      required(:i18n).hash do
        required(:available_locales).array(:string)
        required(:default_locale).filled(:string)
      end
      required(:autotest).hash do
        required(:student_test_buffer_minutes).value(:integer, gt?: 0)
        required(:max_batch_size).value(:integer, gt?: 0)
      end
      optional(:python).filled(:string)
      required(:rails_performance).hash do
        required(:enabled).filled(:bool)
        optional(:duration).value(:integer, gt?: 0)
      end
      required(:exception_notification).hash do
        required(:enabled).filled(:bool)
        optional(:sender).filled(:string)
        optional(:sender_display_name).filled(:string)
        optional(:email_prefix).filled(:string)
        optional(:recipients).array(:str?)
      end
      required(:file_storage).hash do
        required(:default_root_path).filled(:string)
        optional(:scanned_exams).filled(:string)
        optional(:starter_files).filled(:string)
        optional(:autotest).filled(:string)
        optional(:lti).filled(:string)
        optional(:repos).filled(:string)
      end
      optional(:lti).hash do
        optional(:course_filter_file).filled(:string)
        required(:domains).array(:str?)
        required(:token_endpoint).filled(:string)
        optional(:unpermitted_new_course_message).filled(:string)
        required(:sync_schedule).filled(:string)
      end
    end
  end
end
