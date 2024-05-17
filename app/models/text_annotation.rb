class TextAnnotation < Annotation
  validates :line_start, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :line_end, presence: true, numericality: {greater_than_or_equal_to: 1}
  validates :column_start, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :column_end, presence: true, numericality: { greater_than_or_equal_to: 0 }


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
