class AnnotationText < ApplicationRecord

  belongs_to :creator, class_name: 'User', foreign_key: :creator_id
  belongs_to :last_editor, class_name: 'User', foreign_key: :last_editor_id, optional: true

  after_update :update_mark_deductions

  # An AnnotationText has many Annotations that are destroyed when an
  # AnnotationText is destroyed.
  has_many :annotations, dependent: :destroy

  belongs_to :annotation_category, optional: true, counter_cache: true
  validates_associated :annotation_category, on: :create
  byebug
  validates_numericality_of :deduction,
                            if: :should_have_deduction?,
                            greater_than_or_equal_to: 0,
                            less_than_or_equal_to: annotation_category.flexible_criterion.max_mark

  def should_have_deduction?
    byebug
    !((AnnotationCategory.find_by(self.annotation_category_id).flexible_criterion_id).nil?)
  end

  def escape_content
    content.gsub('\\', '\\\\\\') # Replaces '\\' with '\\\\'
           .gsub(/\r?\n/, '\\n')
  end

  def update_mark_deductions
    return unless deduction_changed?
    self.annotations.each do |annotation|
      annotation.result.marks
                .find_by(markable_id: self.annotation_category.flexible_criterion_id,
                         markable_type: 'FlexibleCriteria').update_deduction
    end
  end

  def scale_deduction(scalar)
    return if self.deduction.nil?
    update_attributes!(deduction: (self.deduction * scalar).round(2))
  end
end
