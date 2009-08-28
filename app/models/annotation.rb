class Annotation < ActiveRecord::Base
  belongs_to :submission_file
  belongs_to :annotation_text
  
  validates_presence_of :line_start, :message => 'must have a start line'
  validates_presence_of :line_end, :message => 'must have a end line'
  validates_presence_of :submission_file, :message => 'must have a submission file'
  validates_presence_of :annotation_text, :message => 'must have an annotation label'
  
  validates_associated      :submission_file, :message => 'submission_file associations failed'
  validates_associated      :annotation_text, :message => 'annotation text association failed'
  
  validates_numericality_of :annotation_text_id, :only_integer => true, :greater_than => 0, :message => 'can only be whole number greater than 0.'
  validates_numericality_of :submission_file_id, :only_integer => true, :greater_than => 0, :message => 'can only be whole number greater than 0.'
end
