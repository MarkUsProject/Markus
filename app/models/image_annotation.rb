class ImageAnnotation < Annotation
  # (x1, y1) is the top left corner and (x2, y2) is the bottom right corner
  # of the rectangle containing the annotation.
  validates :x1, :x2, :y1, :y2, presence: true
  validates :x1, :x2, :y1, :y2, numericality: true

  # Return a hash containing the coordinates of the rectangle containing the
  # annotation.
  #
  # ===Returns:
  #
  # A hash with keys id, x1, y1, x2, y2 where (x1, y1) is the top left corner
  # and (x2, y2) is the bottom right corner of the rectangle and id is the
  # annotation_text_id instance.
  def extract_coords
    horiz_range = { start: [x1, x2].min, end: [x1, x2].max }
    vert_range = { start: [y1, y2].min, end: [y1, y2].max }
    { id: annotation_text_id, annot_id: self.id, x_range: horiz_range, y_range: vert_range }
  end

  def get_data(include_creator: false)
    horiz_range = { start: [x1, x2].min, end: [x1, x2].max }
    vert_range = { start: [y1, y2].min, end: [y1, y2].max }

    data = super
    data.merge({
      x_range: horiz_range, y_range: vert_range
    })
  end
end
