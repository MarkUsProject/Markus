ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| "<span class=\"fieldWithErrors\">#{html_tag}</span>" }
CalendarDateSelect.format = :iso_date

# Add module methods to Object class. 
# This makes markus_config_* methods available in the classes
include MarkusConfigurator