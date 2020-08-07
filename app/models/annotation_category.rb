class AnnotationCategory < ApplicationRecord
  # The before_destroy callback must be before the annotation_text association declaration,
  # as it is currently the only way to ensure the annotation_texts do not get destroyed before the callback.
  before_destroy :delete_allowed?

  has_many :annotation_texts, dependent: :destroy

  validates_presence_of :annotation_category_name
  validates_uniqueness_of :annotation_category_name, scope: :assessment_id

  belongs_to :assignment, foreign_key: :assessment_id

  belongs_to :flexible_criterion, required: false
  validates :flexible_criterion_id,
            inclusion: { in: :assignment_criteria, message: '%<value>s is an invalid criterion for this assignment.' }

  before_update :update_annotation_text_deductions, if: lambda { |c|
    changes_to_save.key?('flexible_criterion_id') && c.annotation_texts.exists?
  }

  # Takes an array of comma separated values, and tries to assemble an
  # Annotation Category, and associated Annotation Texts
  # Format:  annotation_category,flexible criterion,annotation_text[, deduction], annotation_text[, deduction]...
  def self.add_by_row(row, assignment, current_user)
    # The first column is the annotation category name.
    return
  end

  def marks_released?
    !self.assignment.released_marks.empty?
  end

  def assignment_criteria
    return [nil] if self.assignment.nil?
    self.assignment.criteria.where(type: 'FlexibleCriterion').ids + [nil]
  end

  def deductive_annotations_exist?
    self.annotation_texts.joins(:annotations).where.not(deduction: [nil, 0]).exists?
  end

  def delete_allowed?
    if marks_released? && deductive_annotations_exist?
      errors.add(:base, 'Cannot delete annotation category once deductions have been applied')
      throw(:abort)
    end
  end

  def update_annotation_text_deductions
    if marks_released?
      errors.add(:base, 'Cannot update annotation category flexible criterion once results are released')
      throw(:abort)
    end
    prev_criterion = FlexibleCriterion.find_by_id(changes_to_save['flexible_criterion_id'].first)
    new_criterion = FlexibleCriterion.find_by_id(changes_to_save['flexible_criterion_id'].second)
    if new_criterion.nil?
      self.annotation_texts.each { |text| text.update!(deduction: nil) }
    elsif prev_criterion.nil?
      self.annotation_texts.each { |text| text.update!(deduction: 0.0) }
    else
      self.annotation_texts.each { |text| text.scale_deduction(new_criterion.max_mark / prev_criterion.max_mark) }
    end
  end
end
