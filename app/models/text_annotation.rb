class TextAnnotation < Annotation

  validates_presence_of :line_start
  validates_presence_of :line_end
  validates_presence_of :column_start
  validates_presence_of :column_end

  def annotation_list_link_partial
    '/annotations/text_annotation_list_link'
  end
end
