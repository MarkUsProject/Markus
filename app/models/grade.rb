# Grade represents an entry in a grade entry form.
class Grade < ApplicationRecord
  belongs_to :grade_entry_item
  belongs_to :grade_entry_student

  validates_numericality_of :grade,
                            greater_than_or_equal_to: 0,
                            message: I18n.t('grade_entry_forms.invalid_grade'),
                            allow_nil: true
end
