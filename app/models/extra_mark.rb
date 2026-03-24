# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: extra_marks
#
#  id          :integer          not null, primary key
#  description :string
#  extra_mark  :float
#  unit        :string
#  created_at  :datetime
#  updated_at  :datetime
#  result_id   :integer
#
# Indexes
#
#  index_extra_marks_on_result_id  (result_id)
#
# Foreign Keys
#
#  fk_extra_marks_results  (result_id => results.id) ON DELETE => cascade
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class ExtraMark < ApplicationRecord
  # When a mark is created, or updated, we need to make sure that that
  # Result that it belongs to has a marking_state of "partial".
  before_save :ensure_not_released_to_students
  before_update :ensure_not_released_to_students

  # When you want to avoid allocating strings...
  PERCENTAGE = 'percentage'.freeze
  POINTS = 'points'.freeze
  PERCENTAGE_OF_MARK = 'percentage_of_mark'.freeze

  scope :percentage, -> { where(unit: ExtraMark::PERCENTAGE) }
  scope :points, -> { where(unit: ExtraMark::POINTS) }
  scope :percentage_of_mark, -> { where(unit: ExtraMark::PERCENTAGE_OF_MARK) }

  validates :unit, presence: true
  validates :unit, format: { with: /\Apercentage|points|percentage_of_mark\z/ }

  scope :positive, -> { where('extra_mark > 0') }
  scope :negative, -> { where('extra_mark < 0') }

  validates :extra_mark, numericality: true

  # TODO: Fix idemptoence
  # Related: https://github.com/MarkUsProject/Markus/pull/7728#discussion_r2488229722
  # validates :description, uniqueness: {
  #   scope: [:result_id, :extra_mark, :unit],
  #   message: 'a mark, unit, description already exist to this result'
  # }

  belongs_to :result

  has_one :course, through: :result

  def ensure_not_released_to_students
    throw(:abort) if result.released_to_students
  end
end
