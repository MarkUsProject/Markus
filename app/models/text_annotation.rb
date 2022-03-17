class TextAnnotation < Annotation
  validates :line_start, presence: true
  validates :line_end, presence: true
  validates :column_start, presence: true
  validates :column_end, presence: true

  def get_data(include_creator: false)
    data = super
    data.merge({
      line_start: line_start,
      line_end: line_end,
      column_start: column_start,
      column_end: column_end
    })
  end
end
