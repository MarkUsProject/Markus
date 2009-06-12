class RubricCriterion < ActiveRecord::Base
  set_table_name "rubric_criteria" # set table name correctly
  belongs_to  :assignment
  has_many    :marks
  validates_associated      :assignment, :message => 'association is not strong with an assignment'
  validates_uniqueness_of :rubric_criterion_name, :scope => :assignment_id, :message => 'is already taken'
  validates_presence_of :rubric_criterion_name, :weight, :assignment_id
  validates_numericality_of :assignment_id, :only_integer => true, :greater_than => 0, :message => "can only be whole number greater than 0"
  validates_numericality_of :weight, :message => "must be a number greater than 0.0", :greater_than => 0.0
  validates_presence_of :level_0_name, :level_1_name, :level_2_name
  validates_presence_of :level_3_name, :level_4_name
  
  
  def mark_for(result_id)
    return marks.find_by_result_id(result_id)
  end
end
