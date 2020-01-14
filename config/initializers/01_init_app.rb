# This string can be seen as a potential XSS vulnerability by rails3, in some cases. Better make it .html_safe
ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| "<span class=\"fieldWithErrors\">#{html_tag}</span>".html_safe }
