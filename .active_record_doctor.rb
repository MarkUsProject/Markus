ActiveRecordDoctor.configure do
  # api_key and schema are NOT NULL but are populated by AutotestSetting's
  # before_create callback (register_autotester), which runs after validation.
  # A presence validator can never pass on create, so these are exempt.
  detector :missing_presence_validation,
           ignore_attributes: [
             'AutotestSetting.api_key',
             'AutotestSetting.schema'
           ]
end
