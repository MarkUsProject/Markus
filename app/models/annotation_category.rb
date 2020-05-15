class AnnotationCategory < ApplicationRecord
  has_many :annotation_texts, dependent: :destroy

  validates_presence_of :annotation_category_name
  validates_uniqueness_of :annotation_category_name, scope: :assessment_id

  belongs_to :assignment, foreign_key: :assessment_id

  belongs_to :flexible_criterion, required: false

  after_update :update_annotation_text_deductions

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

  def update_annotation_text_deductions
    return unless flexible_criterion_id_changed?
    prev_criterion = FlexibleCriterion.find_by_id(previous_changes['flexible_criterion_id'].first)
    new_criterion = FlexibleCriterion.find_by_id(previous_changes['flexible_criterion_id'].second)
    return unless prev_criterion != new_criterion
    if new_criterion.nil?
      self.annotation_texts.each do |text|
        text.update!(deduction: nil)
      end
    elsif prev_criterion.nil?
      text.update!(deduction: 0)
    else
      self.annotation_texts.each do |text|
        text.scale_deduction(new_criterion.max_mark.to_f / prev_criterion.max_mark.to_f)
      end
    end
  end
end
