ActiveRecordDoctor.configure do
  # Remove each override when the detector's existing findings are fixed.
  detector :incorrect_dependent_option, enabled: false
  detector :incorrect_length_validation, enabled: false
  detector :mismatched_foreign_key_type, enabled: false
  detector :missing_foreign_keys, enabled: false
  detector :missing_non_null_constraint, enabled: false
  detector :missing_unique_indexes, enabled: false
  detector :short_primary_key_type, enabled: false
  detector :table_without_primary_key, enabled: false
  detector :undefined_table_references, enabled: false

  # api_key and schema are NOT NULL but are populated by AutotestSetting's
  # before_create callback (register_autotester), which runs after validation.
  # A presence validator can never pass on create, so these are exempt.
  detector :missing_presence_validation,
           ignore_attributes: [
             'AutotestSetting.api_key',
             'AutotestSetting.schema'
           ]
end
