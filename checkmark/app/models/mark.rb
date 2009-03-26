class Mark < ActiveRecord::Base
  belongs_to :rubric_criteria
  belongs_to :result
  validates_presence_of :result_id, :rubric_criteria_id
  validates_numericality_of :result_id, :only_integer => true, :greater_than => 0, :message => "result_id must be an id that is an integer greater than 0"
  validates_numericality_of :mark, :only_integer => true, :greater_than => -1, :less_than =>5, :message => "Mark must be an integer between 0 and 4"
  validates_numericality_of :rubric_criteria_id, :only_integer => true, :greater_than => 0, :message => "Criterion must be an id that is an integer greater than 0"

  #return the current mark for this criterion
  def get_mark
    criterion = RubricCriteria.find(rubric_criteria_id)
    return mark.to_f * criterion.weight
  end
end

