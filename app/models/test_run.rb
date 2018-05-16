class TestRun < ApplicationRecord
  has_many :test_script_results, dependent: :destroy
  belongs_to :test_batch
  belongs_to :grouping, required: true
  belongs_to :user, required: true

  validates_numericality_of :queue_len, greater_than_or_equal_to: 0, only_integer: true, allow_nil: true
  validates_numericality_of :avg_pop_interval, greater_than_or_equal_to: 0, only_integer: true, allow_nil: true
end
