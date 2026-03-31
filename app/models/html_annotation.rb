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
