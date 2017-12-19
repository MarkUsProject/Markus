class Period < ApplicationRecord
  attr_accessor :submission_rule_type

  belongs_to :submission_rule, polymorphic: true
  validates_associated :submission_rule

  validates_presence_of :hours
  validates_numericality_of :hours, greater_than_or_equal_to: 0

  with_options if: :is_penalty_decay_period? do |period|
    period.validates :deduction, presence: true,
      numericality: { greater_than_or_equal_to: 0 }
    period.validates :interval, presence: true,
      numericality: { greater_than_or_equal_to: 0 }
  end

  with_options if: :is_penalty_period? do |period|
    period.validates :deduction, presence: true,
      numericality: { greater_than_or_equal_to: 0 }
  end

  def is_penalty_period?
    self.submission_rule_type == 'PenaltyPeriodSubmissionRule'
  end

  def is_grace_period?
    self.submission_rule_type == 'GracePeriodSubmissionRule'
  end

  def is_penalty_decay_period?
    self.submission_rule_type == 'PenaltyDecayPeriodSubmissionRule'
  end
end
