# Grade represents an entry in a grade entry form.
class Grade < ApplicationRecord

  belongs_to :grade_entry_item
  validates_associated :grade_entry_item

  validates_numericality_of :grade_entry_item_id,
                            only_integer: true,
                            greater_than: 0,
                            message: I18n.t('invalid_id')

  belongs_to :grade_entry_student
  validates_associated :grade_entry_student

  validates_numericality_of :grade_entry_student_id,
                            only_integer: true,
                            greater_than: 0,
                            message: I18n.t('invalid_id')

  validates_numericality_of :grade,
                            greater_than_or_equal_to: 0,
                            message: I18n.t('grade_entry_forms.invalid_grade'),
                            allow_nil: true
end
