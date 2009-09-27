class Mark < ActiveRecord::Base
  # When a mark is created, or updated, we need to make sure that that
  # Result has not been released to students
  before_save :ensure_not_released_to_students
  before_update :ensure_not_released_to_students

  belongs_to :rubric_criterion
  belongs_to :result
  validates_presence_of :result_id, :rubric_criterion_id
  validates_numericality_of :result_id, :only_integer => true, :greater_than => 0, :message => "result_id must be an id that is an integer greater than 0"
  validates_numericality_of :mark, :only_integer => true, :greater_than => -1, :less_than => 5, :message => "Mark must be an integer between 0 and 4"
  validates_numericality_of :rubric_criterion_id, :only_integer => true, :greater_than => 0, :message => "Criterion must be an id that is an integer greater than 0"
  validates_uniqueness_of :rubric_criterion_id, :scope => [:result_id]

  #return the current mark for this criterion
  def get_mark
    criterion = RubricCriterion.find(self.rubric_criterion_id)
    return mark.to_f * criterion.weight
  end
  
  private
  
  def ensure_not_released_to_students
    return !result.released_to_students
  end
end

