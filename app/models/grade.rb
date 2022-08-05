# Grade represents an entry in a grade entry form.
class Grade < ApplicationRecord
  belongs_to :grade_entry_item
  belongs_to :grade_entry_student

  has_one :course, through: :grade_entry_student

  validate :courses_should_match
  validates :grade,
            numericality: { greater_than_or_equal_to: 0,
                            allow_nil: true }
end
