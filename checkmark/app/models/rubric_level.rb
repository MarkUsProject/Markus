class RubricLevel < ActiveRecord::Base
  belongs_to  :rubric_criteria
  validates_associated      :rubric_criteria, :message => 'association is not strong with rubric criteria'
  validates_presence_of :name, :rubric_criteria_id, :level
  validates_numericality_of :rubric_criteria_id, :only_integer => true, :greater_than => 0, :message => "can only be whole number greater than 0"
  validates_numericality_of :level, :message => "must be a whole number greater than 0", :greater_than_or_equal_to => 0, :only_integer => true

end
