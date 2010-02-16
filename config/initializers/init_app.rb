ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| "<span class=\"fieldWithErrors\">#{html_tag}</span>" }
CalendarDateSelect.format = :iso_date

# Add module methods to Object class. 
# This makes markus_config_* methods available in the classes
include MarkusConfigurator

# Unfortunately, at this point in the script (during initialization),
# the I18n hasn't been loaded yet, and these strings are not available.
# This will load up the I18n strings earlier, so that EnsureConfig can
# use the 118n strings. ( With Rails 2.3.5 this is not an issue )
I18n.backend.send(:init_translations)

# checks to make sure that all the config 
# in markus/config/environments/<env_name>.rb is usable
if !Rails.env.test?
  EnsureConfigHelper.check_config()
end
