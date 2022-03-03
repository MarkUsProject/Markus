# This string can be seen as a potential XSS vulnerability by rails3, in some cases. Better escape content.
ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  tag.span html_tag, class: 'fieldWithErrors'
end
