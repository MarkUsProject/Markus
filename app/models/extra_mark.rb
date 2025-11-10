class ExtraMark < ApplicationRecord
  # When a mark is created, or updated, we need to make sure that that
  # Result that it belongs to has a marking_state of "partial".
  before_save :ensure_not_released_to_students
  before_update :ensure_not_released_to_students

  # When you want to avoid allocating strings...
  PERCENTAGE = 'percentage'.freeze
  POINTS = 'points'.freeze
  PERCENTAGE_OF_MARK = 'percentage_of_mark'.freeze
  UNITS = [PERCENTAGE, PERCENTAGE_OF_MARK, POINTS].freeze

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

  def self.valid_unit?(unit)
    UNITS.include?(unit)
  end

  def ensure_not_released_to_students
    throw(:abort) if result.released_to_students
  end
end
