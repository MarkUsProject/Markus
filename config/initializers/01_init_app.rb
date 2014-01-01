# This string can be seen as a potential XSS vulnerability by rails3,
# in some cases. Better make it .html_safe
ActionView::Base.field_error_proc = Proc.new {
  |html_tag, instance| "<span class=\"fieldWithErrors\">
  #{html_tag}</span>".html_safe }

CalendarDateSelect.format = :iso_date

# This makes MARKUS_CONFIG array available in the classes
MARKUS_CONFIG = YAML.load(
  ERB.new(
    File.read("#{::Rails.root}/config/config.yml")).result)[Rails.env]
include MarkusConfigurator

# checks to make sure that all the config
# in markus/config/environments/<env_name>.rb is usable
if !Rails.env.test?
  EnsureConfigHelper.check_config()
end
