class RubricCriterion < ActiveRecord::Base
  set_table_name "rubric_criteria" # set table name correctly
  belongs_to  :assignment
  has_many    :marks
  validates_associated      :assignment, :message => 'association is not strong with an assignment'
  validates_uniqueness_of :rubric_criterion_name, :scope => :assignment_id, :message => 'is already taken'
  validates_presence_of :rubric_criterion_name, :weight, :assignment_id
  validates_numericality_of :assignment_id, :only_integer => true, :greater_than => 0, :message => "can only be whole number greater than 0"
  validates_numericality_of :weight, :message => "must be a number greater than 0.0", :greater_than => 0.0
  
  # Just a small effort here to remove magic numbers...
  RUBRIC_LEVELS = 5
  DEFAULT_WEIGHT = 1.0
  DEFAULT_LEVELS = [
    {'name'=>'Horrible', 'description'=>'This criterion was not satisfied whatsoever'}, 
    {'name'=>'Satisfactory', 'description'=>'This criterion was satisfied'},
    {'name'=>'Good', 'description'=>'This criterion was satisfied well'},
    {'name'=>'Great', 'description'=>'This criterion was satisfied really well!'},
    {'name'=>'Excellent', 'description'=>'This criterion was satisfied excellently'}
  ]
  
  def mark_for(result_id)
    return marks.find_by_result_id(result_id)
  end
  
  def set_default_levels
    DEFAULT_LEVELS.each_with_index do |level, index|
      self['level_' + index.to_s + '_name'] = level['name']
      self['level_' + index.to_s + '_description'] = level['description']
    end
  end
end
