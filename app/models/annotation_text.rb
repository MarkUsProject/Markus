# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: annotation_texts
#
#  id                     :integer          not null, primary key
#  content                :text
#  deduction              :float
#  position               :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  annotation_category_id :integer
#  creator_id             :integer
#  last_editor_id         :integer
#
# Indexes
#
#  index_annotation_texts_on_annotation_category_id  (annotation_category_id)
#  index_annotation_texts_on_creator_id              (creator_id)
#  index_annotation_texts_on_last_editor_id          (last_editor_id)
#
# Foreign Keys
#
#  fk_annotation_labels_annotation_categories  (annotation_category_id => annotation_categories.id) ON DELETE => cascade
#  fk_rails_...                                (creator_id => roles.id)
#  fk_rails_...                                (last_editor_id => roles.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class AnnotationText < ApplicationRecord
  belongs_to :creator, class_name: 'Role', optional: true
  belongs_to :last_editor, class_name: 'Role', optional: true

  has_one :course, through: :creator

  before_validation :set_position, if: :will_save_change_to_annotation_category_id?,
                                   unless: :will_save_change_to_position?
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

  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 1 },
                       uniqueness: { scope: :annotation_category_id },
                       allow_nil: true

  validate :courses_should_match

  def should_have_deduction?
    !self.annotation_category&.flexible_criterion_id.nil?
  end

  # Places this annotation text after the other annotation texts in its annotation category. For backwards
  # compatibility, the other annotation texts are first given positions if any of them do not have one.
  def set_position
    # Lock the annotation category so that annotation texts added to it at the same time get different positions
    category = AnnotationCategory.lock.find_by(id: annotation_category_id)
    if category.nil?
      self.position = nil
    else
      other_texts = category.annotation_texts.where.not(id: id)
      category.update_annotation_text_positions(other_texts.ids) if other_texts.exists?(position: nil)
      self.position = other_texts.maximum(:position).to_i + 1
    end
  end

  def escape_content
    content.gsub('\\', '\\\\\\') # Replaces '\\' with '\\\\'
           .gsub(/\r?\n/, '\\n')
  end

  # Returns the ids of the annotation texts in +texts+ that cannot be changed or deleted because they are used in a
  # released result, or in a submission with a remark request in progress (since submitting a remark request
  # unreleases the original result). Once a remark result has been marked as complete, its submission's annotation
  # texts can be changed again unless it is released. (Annotation texts used in an original result with a remark
  # request still cannot be deleted, as Annotation#check_if_released prevents the deletion of their annotations.)
  def self.released_ids(texts)
    annotations = Annotation.joins(:result).where(annotation_text_id: texts)
    remarks_in_progress = Result.where.not(remark_request_submitted_at: nil)
                                .where(marking_state: Result::MARKING_STATES[:incomplete])
    annotations.where('results.released_to_students': true)
               .or(annotations.where('results.submission_id': remarks_in_progress.select(:submission_id)))
               .distinct
               .pluck(:annotation_text_id)
  end

  # Do not update or destroy this annotation text if it cannot be changed (see AnnotationText.released_ids).
  def check_if_released
    return if AnnotationText.released_ids(self).empty?
    errors.add(:base, :results_already_released)
    throw(:abort)
  end

  def update_mark_deductions
    return unless previous_changes.key?('deduction')
    criterion_id = self.annotation_category.flexible_criterion_id
    annotations = self.annotations.includes(:result)
    annotations.each do |annotation|
      # The mark may not exist yet, e.g. if the criterion was created after the result
      annotation.result.marks
                .find_or_create_by(criterion_id: criterion_id)
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
