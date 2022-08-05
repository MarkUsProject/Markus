class HtmlAnnotation < Annotation
  validates :start_node, presence: true
  validates :start_offset, presence: true
  validates :end_node, presence: true
  validates :end_offset, presence: true

  def get_data(include_creator: false)
    data = super
    data.merge({ start_node: start_node, start_offset: start_offset, end_node: end_node, end_offset: end_offset })
  end
end
