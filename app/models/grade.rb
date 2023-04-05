# Grade represents an entry in a grade entry form.
class Grade < ApplicationRecord
  belongs_to :grade_entry_item
  belongs_to :grade_entry_student

  has_one :course, through: :grade_entry_student

  validate :courses_should_match
  validates :grade,
            numericality: { greater_than_or_equal_to: 0, allow_nil: true }, unless: :bonus_grade?
  validates :grade,
            numericality: { allow_nil: true }, if: :bonus_grade?

  # Return true if the associated grade_entry_item is a bonus column.
  # If grade_entry_item is NIL or a non-bonus column, return false.
  def bonus_grade?
    grade_entry_item.bonus?
  end
end
