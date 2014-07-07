class TextAnnotation < Annotation

  validates_presence_of :line_start
  validates_presence_of :line_end

  def add_annotation_js_string
    "add_annotation(#{id},
                    { start: #{line_start},
                      end: #{line_end} },
                    #{annotation_text_id})"
  end

  def remove_annotation_js_string
    "remove_annotation(#{id},
                       { start: #{line_start},
                         end: #{line_end} },
                       #{annotation_text.id});"
  end

  def annotation_list_link_partial
    '/annotations/text_annotation_list_link'
  end
end
