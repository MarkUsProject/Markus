class HtmlAnnotation < Annotation

  validates_presence_of :start_node
  validates_presence_of :start_offset
  validates_presence_of :end_node
  validates_presence_of :end_offset

  def get_data(include_creator=false)
    data = super
    data.merge({ start_node: start_node, start_offset: start_offset, end_node: end_node, end_offset: end_offset })
  end
end
