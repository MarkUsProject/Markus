class TextAnnotation < Annotation

  validates_presence_of :line_start
  validates_presence_of :line_end
  validates_presence_of :column_start
  validates_presence_of :column_end

  def get_data(include_creator=false)
    data = super
    data.merge({
      line_start: line_start,
      line_end: line_end,
      column_start: column_start,
      column_end: column_end
    })
  end
end
