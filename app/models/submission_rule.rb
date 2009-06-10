class SubmissionRule < ActiveRecord::Base
  
  belongs_to :assignment
  
  validates_numericality_of :allow_submit_until, :only_integer => true,  
    :greater_than_or_equal_to => 0
  
  # make sure to add :if param for validating specific subclasses
  
  # GRACE DAY VALIDATIONS
  
  validates_numericality_of :grace_day_limit, :only_integer => true, 
    :greater_than_or_equal_to => 0, 
    :if => Proc.new { |r| r[:type] == "GraceDaySubmissionRule" }
  
  # PENALTY VALIDATIONS
  
  validates_numericality_of :penalty_limit, :only_integer => true, 
    :greater_than => 0, :if => Proc.new { |r| r[:type] == "PenaltySubmissionRule" }
  
  validates_numericality_of :penalty_increment, :only_integer => true, 
    :greater_than => 0, :if => Proc.new { |r| r[:type] == "PenaltySubmissionRule" }
  
  validates_numericality_of :penalty_interval, :only_integer => true, 
    :greater_than => 0, :if => Proc.new { |r| r[:type] == "PenaltySubmissionRule" }
  
  validates_format_of :penalty_interval_unit, :with => /days|hours|minutes/, 
    :if => Proc.new { |r| r[:type] == "PenaltySubmissionRule" }
  
  # Additional validation logic
  def validate
    # penalty limit must be > penalty increment
    if (penalty_increment && penalty_limit) && penalty_increment > penalty_limit
      errors.add(:penalty_increment, "must be less than the penalty limit.")
    end
  end
  
  
  # all subclasses must define a late submission handle
  # this is independent on whether a student can submit late submissions
  def handle_late_submission(submission)
    return submission
  end
end
