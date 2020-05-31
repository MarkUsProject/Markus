class Mark < ApplicationRecord
  # When a mark is saved, we need to make sure that that
  # Result has not been released to students
  before_save :ensure_not_released_to_students

  after_save :update_result

  belongs_to :result
  
  validates_numericality_of :mark,
                            allow_nil: true,
                            greater_than_or_equal_to: 0,
                            less_than_or_equal_to: ->(m) { m.criterion.max_mark }

  belongs_to :criterion
  validates_uniqueness_of :criterion_id, scope: :result_id

  def scale_mark(curr_max_mark, prev_max_mark, update: true)
    return if mark.nil?
    return 0 if prev_max_mark == 0 || mark == 0 # no scaling occurs if prev_max_mark is 0 or mark is 0
    if criterion.is_a? RubricCriterion
      new_mark = (mark * (curr_max_mark / prev_max_mark)).round(1)
    elsif criterion.is_a? FlexibleCriterion
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
    throw(:abort) if result.released_to_students
  end

  def update_result
    if !mark.nil? || mark_changed?
      result.update_total_mark
    end
    if mark.nil?
      result.update(marking_state: Result::MARKING_STATES[:incomplete])
    end
  end
end
