# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: test_group_results
#
#  id            :integer          not null, primary key
#  error_type    :string
#  extra_info    :text
#  marks_earned  :float            default(0.0), not null
#  marks_total   :float            default(0.0), not null
#  time          :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  test_group_id :integer          not null
#  test_run_id   :integer          not null
#
# Indexes
#
#  index_test_group_results_on_test_group_id  (test_group_id)
#  index_test_group_results_on_test_run_id    (test_run_id)
#
# Foreign Keys
#
#  fk_rails_...  (test_group_id => test_groups.id)
#  fk_rails_...  (test_run_id => test_runs.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
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
