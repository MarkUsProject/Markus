class Mark < ApplicationRecord
  # When a mark is saved, we need to make sure that that
  # Result has not been released to students
  before_save :ensure_not_released_to_students

  after_save :update_result_mark

  belongs_to :result
  validates_presence_of :result_id, :markable_id, :markable_type
  validates_numericality_of :result_id,
                            only_integer: true,
                            greater_than: 0,
                            message: 'result_id must be an id that is an integer greater than 0'

  validates_numericality_of :mark,
                            allow_nil: true,
                            greater_than_or_equal_to: 0,
                            message: I18n.t('marker.marks.invalid_mark')
  validate :valid_mark

  belongs_to :markable, polymorphic: true
  validates_numericality_of :markable_id,
                            only_integer: true,
                            greater_than_or_equal_to: 0,
                            message: 'Criterion must be an id that is an integer greater than 0'

  validates_uniqueness_of :markable_id,
                          scope: [:result_id, :markable_type]

  # Custom validator for checking the upper range of a mark
  def valid_mark
    unless mark.nil?
      if mark > markable.max_mark
        errors.add(:mark, I18n.t('mark.error.validate_criteria'))
      end
    end
  end

  def scale_mark(curr_max_mark, prev_max_mark, update: true)
    return if mark.nil?
    return 0 if prev_max_mark == 0 || mark == 0 # no scaling occurs if prev_max_mark is 0 or mark is 0
    if markable.is_a? RubricCriterion
      new_mark = (mark * (curr_max_mark / prev_max_mark)).round(1)
    elsif markable.is_a? FlexibleCriterion
      new_mark = (mark * (curr_max_mark.to_f / prev_max_mark)).round(2)
    else # if it is CheckboxCriterion
      new_mark = ((mark / prev_max_mark) * curr_max_mark).round(0)
    end
    if update
      # Use update_columns to skip validations.
      update_columns(mark: new_mark)
    end
    new_mark
  end

  private

  def ensure_not_released_to_students
    !result.released_to_students
  end

  def update_result_mark
    if !mark.nil? || mark_changed?
      result.update_total_mark
    end
  end
end
