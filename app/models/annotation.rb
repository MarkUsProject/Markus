class Annotation < ActiveRecord::Base
  belongs_to :submission_file
  belongs_to :annotation_text

  validates_presence_of :submission_file
  validates_presence_of :annotation_text
  validates_presence_of :annotation_number
  validates_inclusion_of :is_remark, :in => [true, false]

  validates_associated      :submission_file
  validates_associated      :annotation_text

  validates_numericality_of :annotation_text_id, :only_integer => true, :greater_than => 0
  validates_numericality_of :submission_file_id, :only_integer => true, :greater_than => 0
  validates_numericality_of :annotation_number, :only_integer => true, :greater_than => 0

  validates_format_of       :type,               :with => /ImageAnnotation|TextAnnotation/
end
