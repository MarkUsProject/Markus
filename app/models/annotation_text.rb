class AnnotationText < ApplicationRecord

  belongs_to :creator, class_name: 'User', foreign_key: :creator_id
  belongs_to :last_editor, class_name: 'User', foreign_key: :last_editor_id, optional: true

  after_update :update_mark_deductions
  before_update :check_if_released
  before_destroy :check_if_released

  # An AnnotationText has many Annotations that are destroyed when an
  # AnnotationText is destroyed.
  has_many :annotations, dependent: :destroy

  belongs_to :annotation_category, optional: true, counter_cache: true
  validates_associated :annotation_category, on: :create

  validates_numericality_of :deduction,
                            if: :should_have_deduction?,
                            greater_than_or_equal_to: 0,
                            less_than_or_equal_to: ->(t) { t.annotation_category.flexible_criterion.max_mark }

  validates_absence_of :deduction, unless: :should_have_deduction?

  def should_have_deduction?
    !self&.annotation_category&.flexible_criterion_id.nil?
  end

  def escape_content
    content.gsub('\\', '\\\\\\') # Replaces '\\' with '\\\\'
           .gsub(/\r?\n/, '\\n')
  end

  def check_if_released
    # Cannot update if any results have been released with the annotation and the deduction is non nil
    return if self.annotations.joins(:result).where('results.released_to_students' => true).empty? ||
        self.deduction.nil?
    errors.add(:base, 'Cannot update/destroy annotation_text once results are released.')
    throw(:abort)
  end

  def update_mark_deductions
    return unless previous_changes.key?('deduction')

    if self.annotation_category.changes_to_save.key?('flexible_criterion_id')
      criterion = FlexibleCriterion.find_by(id: self.annotation_category
                                                    .changes_to_save['flexible_criterion_id']
                                                    .first)
      return if criterion.nil? || criterion.marks == []
      criterion_id = self.annotation_category.changes_to_save['flexible_criterion_id'].first
    else
      criterion_id = self.annotation_category.flexible_criterion_id
    end
    annotations = self.annotations.includes(:result)
    annotations.each do |annotation|
      annotation.result.marks
                .find_by(markable_id: criterion_id,
                         markable_type: 'FlexibleCriterion').update_deduction
    end
  end

  def scale_deduction(scalar)
    return if self.deduction.nil?
    prev_deduction = self.deduction
    self.update!(deduction: (prev_deduction * scalar).round(2))
  end
end
