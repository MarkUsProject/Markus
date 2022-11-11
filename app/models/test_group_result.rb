class TestGroupResult < ApplicationRecord
  has_many :test_results, dependent: :destroy
  belongs_to :test_group
  belongs_to :test_run

  has_many :feedback_files, dependent: :destroy
  has_one :course, through: :test_run

  validates :marks_earned, :marks_total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :courses_should_match

  ERROR_TYPE = {
    no_results: :no_results,
    timeout: :timeout,
    test_error: :test_error
  }.freeze
end
