class AnnotationCategory < ApplicationRecord
  before_update :check_if_marks_released, if: ->(c) {
    changes_to_save.key?('flexible_criterion_id') && c.annotation_texts.exists?
  }
  around_update :update_annotation_text_deductions, if: ->(c) {
    changes_to_save.key?('flexible_criterion_id') && c.annotation_texts.exists?
  }

  # The before_destroy callback must be before the annotation_text association declaration,
  # as it is currently the only way to ensure the annotation_texts do not get destroyed before the callback.
  before_destroy :delete_allowed?

  has_many :annotation_texts, dependent: :destroy

  validates :annotation_category_name, presence: true
  validates :annotation_category_name, uniqueness: { scope: :assessment_id }

  belongs_to :assignment, foreign_key: :assessment_id, inverse_of: :annotation_categories

  has_one :course, through: :assignment

  belongs_to :flexible_criterion, optional: true
  # Note that there is no need to validate that courses match through courses_should_match
  # because the flexible_criterion_id must be associated to the same assignment.
  validates :flexible_criterion_id,
            inclusion: { in: :assignment_criteria, message: '%<value>s is an invalid criterion for this assignment.' }

  # Takes an array of comma separated values, and tries to assemble an
  # Annotation Category, and associated Annotation Texts
  # Format:  annotation_category,flexible criterion,annotation_text[, deduction], annotation_text[, deduction]...
  def self.add_by_row(row, assignment, current_role)
    # The first column is the annotation category name.
    name = row.shift
    annotation_category = assignment.annotation_categories.find_by(annotation_category_name: name)
    # The second column is the optional flexible criterion name.
    criterion_name = row.shift
    criterion_name = nil if criterion_name.blank?
    if annotation_category.nil?
      annotation_category = assignment.annotation_categories.create(annotation_category_name: name)
      unless annotation_category.valid?
        raise CsvInvalidLineError, I18n.t('annotation_categories.upload.empty_category_name')
      end
    elsif annotation_category.flexible_criterion&.name != criterion_name
      raise CsvInvalidLineError, I18n.t('annotation_categories.upload.invalid_criterion',
                                        annotation_category: name)
    end
    if criterion_name.nil?
      row.each do |text|
        annotation_text = annotation_category.annotation_texts.build(
          content: text,
          creator_id: current_role.id,
          last_editor_id: current_role.id
        )
        unless annotation_text.save
          raise CsvInvalidLineError, I18n.t('annotation_categories.upload.error',
                                            annotation_category: annotation_category.annotation_category_name)
        end
      end
    else
      criterion = assignment.criteria.find_by(name: criterion_name, type: 'FlexibleCriterion')
      if criterion.nil?
        raise CsvInvalidLineError, I18n.t('annotation_categories.upload.criterion_not_found',
                                          missing_criterion: criterion_name)
      end
      annotation_category.update!(flexible_criterion_id: criterion.id)
      row.each_slice(2) do |text_with_deduction|
        begin
          new_deduction = Float(text_with_deduction.second)
        rescue ArgumentError, TypeError
          raise CsvInvalidLineError, I18n.t('annotation_categories.upload.deduction_absent',
                                            value: text_with_deduction.second,
                                            annotation_category: annotation_category.annotation_category_name)
        end
        if new_deduction > criterion.max_mark || new_deduction < 0
          raise CsvInvalidLineError, I18n.t('annotation_categories.upload.invalid_deduction',
                                            annotation_content: text_with_deduction.first,
                                            criterion_name: criterion_name,
                                            value: new_deduction)
        end
        annotation_text = annotation_category.annotation_texts.build(
          content: text_with_deduction.first,
          creator_id: current_role.id,
          last_editor_id: current_role.id,
          deduction: new_deduction.round(2)
        )
        unless annotation_text.save
          raise CsvInvalidLineError, I18n.t('annotation_categories.upload.error',
                                            annotation_category: annotation_category.annotation_category_name)
        end
      end
    end
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

  def check_if_marks_released
    if marks_released?
      errors.add(:base, 'Cannot update annotation category flexible criterion once results are released')
      throw(:abort)
    end
  end

  def update_annotation_text_deductions
    prev_criterion = FlexibleCriterion.find_by(id: changes_to_save['flexible_criterion_id'].first)
    new_criterion = FlexibleCriterion.find_by(id: changes_to_save['flexible_criterion_id'].second)
    if new_criterion.nil?
      self.annotation_texts.each { |text| text.update!(deduction: nil) }
    elsif prev_criterion.nil?
      self.annotation_texts.each { |text| text.update!(deduction: 0.0) }
    else
      self.annotation_texts.each { |text| text.scale_deduction(new_criterion.max_mark / prev_criterion.max_mark) }
    end

    yield

    results_to_update = Result.joins(annotations: :annotation_text)
                              .where('annotation_texts.annotation_category_id': self.id)

    unless new_criterion.nil?
      results_to_update.each do |result|
        result.marks.find_or_create_by(criterion_id: new_criterion.id).update_deduction
      end
    end

    unless prev_criterion.nil?
      results_to_update.each do |result|
        result.marks.find_or_create_by(criterion_id: prev_criterion.id).update_deduction
      end
    end
  end

  # Return all visible annotation categories associated with +assignment+ for +role+.
  #
  # This will return all annotation categories for instructors and no instructor categories for students.
  # If graders are assigned annotation categories, then only return assigned categories, otherwise
  # treat graders the same as instructors.
  def self.visible_categories(assignment, role)
    return AnnotationCategory.none unless role.ta? || role.instructor?

    if role.ta? && assignment.assign_graders_to_criteria
      visible = role.criterion_ta_associations.joins(:criterion).pluck(:criterion_id) + [nil]
      assignment.annotation_categories.order(:position).where('annotation_categories.flexible_criterion_id': visible)
    else
      assignment.annotation_categories.order(:position)
    end
  end
end
