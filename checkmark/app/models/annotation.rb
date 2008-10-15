class Annotation < ActiveRecord::Base
  belongs_to :assignment_file
  belongs_to :description
  
  validates_presence_of :pos_start, :message => 'must have a start position'
  validates_presence_of :pos_end, :message => 'must have a end position'
  validates_presence_of :line_start, :message => 'must have a start line'
  validates_presence_of :line_end, :message => 'must have a end line'
  
  validates_associated      :assignment_file, :message => 'assignment_file associations failed'
  validates_associated      :description, :message => 'description associations failed'
  
  validates_numericality_of :description_id, :only_integer => true, :greater_than => 0, :message => 'can only be whole number greater than 0.'
  validates_numericality_of :assignmentfile_id, :only_integer => true, :greater_than => 0, :message => 'can only be whole number greater than 0.'
end
