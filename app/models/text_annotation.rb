class TextAnnotation < Annotation

  validates :line_start, presence: value
  validates :line_end, presence: value
  validates :column_start, presence: value
  validates :column_end, presence: value

  def annotation_list_link_partial
    '/annotations/text_annotation_list_link'
  end
end
