# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: test_results
#
#  id                   :integer          not null, primary key
#  marks_earned         :float            default(0.0), not null
#  marks_total          :float            default(0.0), not null
#  name                 :text             not null
#  output               :text             default(""), not null
#  position             :integer          not null
#  status               :text             not null
#  time                 :bigint
#  created_at           :datetime
#  updated_at           :datetime
#  test_group_result_id :bigint           not null
#
# Indexes
#
#  index_test_results_on_test_group_result_id  (test_group_result_id)
#
# Foreign Keys
#
#  fk_rails_...  (test_group_result_id => test_group_results.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class TestResult < ApplicationRecord
  belongs_to :test_group_result
  has_one :course, through: :test_group_result

  validates :name, presence: true, uniqueness: { scope: :test_group_result }
  validates :status, presence: true, inclusion: { in: %w[pass partial fail error error_all] }
  validates :marks_earned, :marks_total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time, numericality: { greater_than_or_equal_to: 0, only_integer: true, allow_nil: true }
  # output could be empty in some situations
  validates :output, presence: true, if: ->(o) { o.output.nil? }
end
