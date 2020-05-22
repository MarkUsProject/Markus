class AnnotationCategory < ApplicationRecord
  has_many :annotation_texts, dependent: :destroy

  validates_presence_of :annotation_category_name
  validates_uniqueness_of :annotation_category_name, scope: :assessment_id

  belongs_to :assignment, foreign_key: :assessment_id

  belongs_to :flexible_criterion, required: false

  before_update :update_annotation_text_deductions
  before_destroy :check_if_deductions_exist

  # Takes an array of comma separated values, and tries to assemble an
  # Annotation Category, and associated Annotation Texts
  # Format:  annotation_category,annotation_text,annotation_text,...
  def self.add_by_row(row, assignment, current_user)
    # The first column is the annotation category name.
    name = row.shift
    annotation_category = assignment.annotation_categories.find_or_create_by(
      annotation_category_name: name
    )

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
  end

  def marks_not_released?
    return true if self.flexible_criterion.nil?
    self.flexible_criterion.marks.joins(:result).where('results.released_to_students' => true).empty?
  end

  def check_if_deductions_exist
    byebug
    return if marks_not_released? || self.annotation_texts.joins(:annotations).where.not(deduction: nil).empty?
    errors.add(:base, 'Cannot delete annotation category once deductions have been applied')
    throw(:abort)
  end

  def update_annotation_text_deductions
    return unless changes_to_save.key?('flexible_criterion_id')

    unless marks_not_released?
      errors.add(:base, 'Cannot update annotation category flexible criterion once results are released.')
      throw(:abort)
    end

    return if self.annotation_texts.nil?
    prev_criterion = FlexibleCriterion.find_by_id(changes_to_save['flexible_criterion_id'].first)
    new_criterion = FlexibleCriterion.find_by_id(changes_to_save['flexible_criterion_id'].second)
    return unless prev_criterion != new_criterion
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
