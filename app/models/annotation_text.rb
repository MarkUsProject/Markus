class AnnotationText < ApplicationRecord
  belongs_to :creator, class_name: 'Role'
  belongs_to :last_editor, class_name: 'Role', optional: true

  has_one :course, through: :creator

  before_update :check_if_released
  after_update :update_mark_deductions,
               unless: ->(t) {
                         t.annotation_category.nil? ||
                         t.annotation_category.changes_to_save.key?('flexible_criterion_id')
                       }

  before_destroy :check_if_released

  # An AnnotationText has many Annotations that are destroyed when an
  # AnnotationText is destroyed.
  has_many :annotations, dependent: :destroy

  belongs_to :annotation_category, optional: true
  validates_associated :annotation_category, on: :create

  validates :deduction,
            numericality: { if: :should_have_deduction?,
                            greater_than_or_equal_to: 0,
                            less_than_or_equal_to: ->(t) { t.annotation_category.flexible_criterion.max_mark } }

  validates :deduction, absence: { unless: :should_have_deduction? }

  validate :courses_should_match

  def should_have_deduction?
    !self.annotation_category&.flexible_criterion_id.nil?
  end

  def escape_content
    content.gsub('\\', '\\\\\\') # Replaces '\\' with '\\\\'
           .gsub(/\r?\n/, '\\n')
  end

  # Do not update if any associated results have been released. This includes results
  # that were previously released and are now the subject of a remark request.
  def check_if_released
    annotation_results = self.annotations.joins(result: :submission)

    return if annotation_results.where('results.released_to_students': true).empty? &&
              Result.where(submission_id: annotation_results.pluck('submissions.id'))
                    .where.not(remark_request_submitted_at: nil)
                    .empty?
    errors.add(:base, 'Cannot update/destroy annotation_text once results are released.')
    throw(:abort)
  end

  def update_mark_deductions
    return unless previous_changes.key?('deduction')
    criterion_id = self.annotation_category.flexible_criterion_id
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
        .joins('INNER JOIN roles ON annotations.creator_id = roles.id')
        .joins('INNER JOIN users ON roles.user_id = users.id')
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
