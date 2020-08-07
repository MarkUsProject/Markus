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
    name = row.shift
    annotation_category = assignment.annotation_categories.find_by(annotation_category_name: name)
    # The second column is the optional flexible criterion name.
    criterion_name = row.shift
    if annotation_category.nil?
      annotation_category = assignment.annotation_categories.create(annotation_category_name: name)
      unless annotation_category.valid?
        raise CsvInvalidLineError, I18n.t('annotation_categories.upload.empty_category_name')
      end
    elsif (annotation_category.flexible_criterion_id.nil? && !criterion_name.nil?) ||
          (annotation_category.flexible_criterion.name != criterion_name)
      raise CsvInvalidLineError, I18n.t('annotation_categories.upload.invalid_criterion',
                                        annotation_category: name)
    end
    if criterion_name.nil?
      row.each do |text|
        annotation_text = annotation_category.annotation_texts.build(
          content: text,
          creator_id: current_user.id,
          last_editor_id: current_user.id
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
          creator_id: current_user.id,
          last_editor_id: current_user.id,
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
