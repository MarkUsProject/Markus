class Mark < ApplicationRecord
  # When a mark is saved, we need to make sure that that
  # Result has not been released to students
  before_save :ensure_not_released_to_students

  after_save :update_result
  after_update :update_deduction, if: lambda { |m|
    m.previous_changes.key?('override') && !m.override && m.criterion.type == 'FlexibleCriterion'
  }

  belongs_to :result

  validates_numericality_of :mark,
                            allow_nil: true,
                            greater_than_or_equal_to: 0,
                            less_than_or_equal_to: ->(m) { m.criterion.max_mark }

  belongs_to :criterion
  validates_uniqueness_of :criterion_id, scope: :result_id

  validates_inclusion_of :override, in: [true, false]

  def calculate_deduction
    return 0 if self.override? || self.criterion.type != 'FlexibleCriterion'

    self.result
        .annotations
        .joins(annotation_text: [{ annotation_category: :flexible_criterion }])
        .where('criteria.id': self.criterion_id)
        .sum(:deduction)
  end

  def deductive_annotations_absent?
    self.result
        .annotations
        .joins(annotation_text: [{ annotation_category: :flexible_criterion }])
        .where('criteria.id': self.criterion_id)
        .where.not('annotation_texts.deduction': 0).empty?
  end

  def update_deduction
    if self.mark.nil? && deductive_annotations_absent?
      return self.update!(override: false)
    end
    return if self.override?
    deduction = calculate_deduction
    if deduction == 0
      return self.update!(mark: nil)
    elsif deduction > self.criterion.max_mark
      return self.update!(mark: 0.0)
    else
      return self.update!(mark: self.criterion.max_mark - deduction)
    end
  end

  def scale_mark(curr_max_mark, prev_max_mark, update: true)
    return if mark.nil?
    return 0 if prev_max_mark == 0 || mark == 0 # no scaling occurs if prev_max_mark is 0 or mark is 0
    if criterion.is_a? CheckboxCriterion
      new_mark = curr_max_mark
    else
      new_mark = (mark * (curr_max_mark.to_f / prev_max_mark)).round(2)
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
