# This string can be seen as a potential XSS vulnerability by rails3, in some cases. Better make it .html_safe
ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| "<span class=\"fieldWithErrors\">#{html_tag}</span>".html_safe }
CalendarDateSelect.format = :iso_date

# Add module methods to Object class.
# This makes markus_config_* methods available in the classes
include MarkusConfigurator

# checks to make sure that all the config
# in markus/config/environments/<env_name>.rb is usable
if !Rails.env.test?
  EnsureConfigHelper.check_config()
end
