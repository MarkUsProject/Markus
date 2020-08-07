class AnnotationText < ApplicationRecord

  belongs_to :creator, class_name: 'User', foreign_key: :creator_id
  belongs_to :last_editor, class_name: 'User', foreign_key: :last_editor_id, optional: true

  after_update :update_mark_deductions
  before_update :check_if_released, unless: ->(t) { t.deduction.nil? }
  before_destroy :check_if_released, unless: ->(t) { t.deduction.nil? }

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
    return if self.annotations.joins(:result).where('results.released_to_students' => true).empty?
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
                .find_by(criterion_id: criterion_id)
                .update_deduction
    end
  end

  def scale_deduction(scalar)
    return if self.deduction.nil?
    prev_deduction = self.deduction
    self.update!(deduction: (prev_deduction * scalar).round(2))
  end

  def uses
    # TODO: simplify second join once creator is no longer polymoprhic
    self.annotations
        .joins(result: { grouping: :group })
        .joins('INNER JOIN users ON annotations.creator_id = users.id')
        .order('groups.group_name')
        .group('results.id',
               'groupings.assessment_id',
               'results.submission_id',
               'groups.group_name',
               'users.first_name',
               'users.last_name',
               'users.user_name')
        .pluck_to_hash('results.id AS result_id',
                       'groupings.assessment_id AS assignment_id',
                       'results.submission_id AS submission_id',
                       'groups.group_name AS group_name',
                       'users.first_name AS first_name',
                       'users.last_name AS last_name',
                       'users.user_name AS user_name',
                       Arel.sql('count(*) AS count'))
  end
end
