# Grade represents an entry in a grade entry form.
# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: grades
#
#  id                     :integer          not null, primary key
#  grade                  :float
#  created_at             :datetime
#  updated_at             :datetime
#  grade_entry_item_id    :integer
#  grade_entry_student_id :integer
#
# Indexes
#
#  index_grades_on_grade_entry_item_id_and_grade_entry_student_id  (grade_entry_item_id,grade_entry_student_id) UNIQUE
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
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
    return false if grade_entry_item.nil?
    grade_entry_item.bonus?
  end
end
