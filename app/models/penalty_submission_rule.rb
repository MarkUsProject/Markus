class PenaltySubmissionRule < SubmissionRule

#  has_many :periods, :as => :submission_rule
#  accepts_nested_attributes_for :periods, :allow_destroy => true
  
  validates_numericality_of :penalty_limit, :only_integer => true, 
    :greater_than => 0
  
  validates_numericality_of :penalty_increment, :only_integer => true, 
    :greater_than => 0
  
  validates_numericality_of :penalty_interval, :only_integer => true, 
    :greater_than => 0, :if => Proc.new { |r| r[:type] == "PenaltySubmissionRule" }
  
  validates_format_of :penalty_interval_unit, :with => /days|hours|minutes/

  def validate
    # penalty limit must be > penalty increment
    if (penalty_increment && penalty_limit) && penalty_increment > penalty_limit
      errors.add(:penalty_increment, "must be less than the penalty limit.")
    end
  end
  
  def initialize
    
  end
end
