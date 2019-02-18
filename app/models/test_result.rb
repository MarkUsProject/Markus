class TestResult < ApplicationRecord
  belongs_to :test_group_result

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: %w[pass partial fail error] }
  validates :marks_earned, :marks_total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time, numericality: { greater_than_or_equal_to: 0, only_integer: true, allow_nil: true }
  # output could be empty in some situations
  validates :output, presence: true, if: ->(o) { o.output.nil? }
end
