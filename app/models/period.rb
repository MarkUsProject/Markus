class Period < ApplicationRecord
  belongs_to :submission_rule, polymorphic: true

  validates_numericality_of :hours, greater_than: 0
  validates_numericality_of :deduction, greater_than_or_equal_to: 0, if: :check_deduction
  validates_numericality_of :interval, greater_than: 0, if: :check_interval

  before_create -> { self.submission_rule_type = submission_rule.type }

  # This is used instead of a has_one through: :submission_rule because Rails
  # does not support associations through other polymorphic associations
  def course
    self.submission_rule.course
  end

  private

  def check_deduction
    %w[PenaltyDecayPeriodSubmissionRule PenaltyPeriodSubmissionRule].include? submission_rule&.type
  end

  def check_interval
    submission_rule&.type == 'PenaltyDecayPeriodSubmissionRule'
  end
end
