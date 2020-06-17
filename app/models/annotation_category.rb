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

  before_update :update_annotation_text_deductions

  def assignment_criteria
    return [nil] if self.assignment.nil?
    self.assignment.flexible_criteria.ids + [nil]
  end

  # Takes an array of comma separated values, and tries to assemble an
  # Annotation Category, and associated Annotation Texts
  # Format:  annotation_category,annotation_text,annotation_text,...
  def self.add_by_row(row, assignment, current_user)
    # The first column is the annotation category name.
    name = row.shift
    annotation_category = assignment.annotation_categories.find_or_create_by(
      annotation_category_name: name
    )
    raise CsvInvalidLineError unless annotation_category.valid?
    # The second column is the optional flexible criterion name.
    criterion_name = row.shift
    if criterion_name.nil?
      row.each do |text|
        annotation_text = annotation_category.annotation_texts.build(
          content: text,
          creator_id: current_user.id,
          last_editor_id: current_user.id
        )
        unless annotation_text.save
          raise CsvInvalidLineError
        end
      end
    else
      criterion = assignment.flexible_criteria.find_by(name: criterion_name)
      annotation_category.update!(flexible_criterion_id: criterion.id)
      row.each_slice(2) do |text_with_deduction|
        annotation_text = annotation_category.annotation_texts.build(
          content: text_with_deduction.first,
          creator_id: current_user.id,
          last_editor_id: current_user.id,
          deduction: text_with_deduction.second.to_f
        )
        unless annotation_text.save
          raise CsvInvalidLineError
        end
      end
    end
  end

  def marks_released?
    !self.assignment.released_marks.empty?
  end

  def deductive_annotations_exist?
    !self.annotation_texts.joins(:annotations).where.not(deduction: nil).empty?
  end

  def delete_allowed?
    if marks_released? && deductive_annotations_exist?
      errors.add(:base, 'Cannot delete annotation category once deductions have been applied')
      throw(:abort)
    end
  end

  def update_annotation_text_deductions
    return if !changes_to_save.key?('flexible_criterion_id') || self.annotation_texts.empty?

    if marks_released?
      errors.add(:base, 'Cannot update annotation category flexible criterion once results are released')
      throw(:abort)
    end
    prev_criterion = FlexibleCriterion.find_by_id(changes_to_save['flexible_criterion_id'].first)
    new_criterion = FlexibleCriterion.find_by_id(changes_to_save['flexible_criterion_id'].second)
    if new_criterion.nil?
      self.annotation_texts.each do |text|
        text.update!(deduction: nil)
      end
    elsif prev_criterion.nil?
      self.annotation_texts.each do |text|
        text.update!(deduction: 0.0)
      end
    else
      self.annotation_texts.each do |text|
        text.scale_deduction(new_criterion.max_mark / prev_criterion.max_mark)
      end
    end
  end
end
