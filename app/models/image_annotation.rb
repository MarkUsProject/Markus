# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: annotations
#
#  id                 :integer          not null, primary key
#  annotation_number  :integer
#  column_end         :integer
#  column_start       :integer
#  creator_type       :string
#  end_node           :string
#  end_offset         :integer
#  is_remark          :boolean          default(FALSE), not null
#  line_end           :integer
#  line_start         :integer
#  page               :integer
#  start_node         :string
#  start_offset       :integer
#  type               :string
#  x1                 :integer
#  x2                 :integer
#  y1                 :integer
#  y2                 :integer
#  annotation_text_id :integer
#  creator_id         :integer
#  result_id          :integer
#  submission_file_id :integer
#
# Indexes
#
#  index_annotations_on_creator_type_and_creator_id  (creator_type,creator_id)
#  index_annotations_on_submission_file_id           (submission_file_id)
#
# Foreign Keys
#
#  fk_annotations_annotation_texts  (annotation_text_id => annotation_texts.id)
#  fk_annotations_submission_files  (submission_file_id => submission_files.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
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
