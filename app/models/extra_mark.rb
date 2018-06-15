class ExtraMark < ApplicationRecord
  # When a mark is created, or updated, we need to make sure that that
  # Result that it belongs to has a marking_state of "partial".
  before_save :ensure_not_released_to_students
  before_update :ensure_not_released_to_students

  # When you want to avoid allocating strings...
  PERCENTAGE = 'percentage'
  POINTS     = 'points'

  scope :percentage, -> { where(unit: ExtraMark::PERCENTAGE) }
  scope :points,     -> { where(unit: ExtraMark::POINTS)     }

  validates_presence_of :unit
  validates_format_of   :unit, with: /percentage|points/

  scope :positive, -> { where('extra_mark > 0') }
  scope :negative, -> { where('extra_mark < 0') }

  validates_numericality_of :extra_mark, message: 'Mark must be an number'

  belongs_to :result

  def ensure_not_released_to_students
    !result.released_to_students
  end
end
