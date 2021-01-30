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
  config.schema do
    required(:rails).hash do
      required(:time_zone).value(included_in?: ActiveSupport::TimeZone::MAPPING.keys)
      required(:cache_classes).filled(:bool)
      required(:eager_load).filled(:bool)
      required(:consider_all_requests_local).filled(:bool)
      optional(:hosts).array(:string)
      required(:log_level).filled(included_in?: %w[debug info warn error fatal unknown])
      required(:active_support).hash do
        required(:deprecation).filled(included_in?: ActiveSupport::Deprecation::DEFAULT_BEHAVIORS.keys.map(&:to_s))
      end
      optional(:perform_caching).filled(:bool)
      optional(:cache_store).filled(:string)
      optional(:active_record).hash do
        optional(:verbose_query_logs).filled(:bool)
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
        required(:default_url_options).hash
        required(:asset_host).filled(:string)
        required(:perform_deliveries).filled(:bool)
        required(:deliver_later_queue_name).maybe(:string)
      end
    end
    required(:queues).hash do
      required(:default).filled(:string)
      optional(:autotest_cancel_job).filled(:string)
      optional(:autotest_run_job).filled(:string)
      optional(:autotest_specs_job).filled(:string)
      optional(:autotest_testers_job).filled(:string)
      optional(:create_groups_job).filled(:string)
      optional(:download_submissions_job).filled(:string)
      optional(:generate_job).filled(:string)
      optional(:split_pdf_job).filled(:string)
      optional(:submissions_job).filled(:string)
      optional(:uncollect_submissions_job).filled(:string)
      optional(:update_keys_job).filled(:string)
      optional(:update_repo_required_files_job).filled(:string)
    end
    required(:redis).hash do
      required(:url).filled(:string)
    end
    required(:course_name).filled(:string)
    required(:validate_file).filled(:string)
    required(:validate_ip).filled(:bool)
    required(:validate_custom_exit_status).maybe(:string)
    required(:validate_custom_status_message).maybe(:string)
    required(:validate_user_not_allowed_message).maybe(:string)
    required(:incorrect_login_message).maybe(:string)
    required(:remote_user_auth).filled(:bool)
    required(:logout_redirect).filled(:string)
    required(:repository).hash do
      required(:storage).filled(:string)
      required(:permission_file).filled(:string)
      required(:type).value(included_in?: %w[git svn mem])
      optional(:git_shell).filled(:string)
      required(:url).filled(:string)
      optional(:ssh_url).filled(:string)
      required(:is_repository_admin).filled(:bool)
    end
    required(:max_file_size).value(:integer, gt?: 0)
    required(:student_session_timeout).value(:integer, gt?: 0)
    required(:ta_session_timeout).value(:integer, gt?: 0)
    required(:admin_session_timeout).value(:integer, gt?: 0)
    required(:enable_key_storage).filled(:bool)
    required(:key_storage).filled(:string)
    required(:student_csv_upload_order).array(
      included_in?: %w[user_name last_name first_name section_name id_number email]
    )
    required(:ta_csv_upload_order).array(included_in?: %w[user_name last_name first_name email])
    required(:logging).hash do
      required(:enabled).filled(:bool)
      required(:rotate_by_interval).filled(:bool)
      optional(:rotate_interval).filled(included_in?: %w[daily weekly monthly])
      required(:size_threshold).filled(:integer, gt?: 0)
      required(:old_files).filled(:integer, gt?: 0)
      required(:log_file).filled(:string)
      required(:error_file).filled(:string)
    end
    required(:scanned_exams).hash do
      required(:enable).filled(:bool)
      required(:python).filled(:string)
      required(:path).filled(:string)
    end
    required(:nbconvert).filled(:string)
    required(:i18n).hash do
      required(:available_locales).array(:string)
      required(:default_locale).filled(:string)
    end
    required(:autotest).hash do
      required(:client_dir).filled(:string)
      required(:max_batch_size).value(:integer, gt?: 0)
    end
    required(:starter_file).hash do
      required(:storage).filled(:string)
    end
  end
end
