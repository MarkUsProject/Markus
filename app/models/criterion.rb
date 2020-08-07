# The abstract base class that defines common behavior for all types of
# criterion.
class Criterion < ApplicationRecord
  belongs_to :assignment, foreign_key: :assessment_id
  after_update :scale_marks
  before_destroy :update_results

  has_many :marks, dependent: :destroy
  accepts_nested_attributes_for :marks

  validates_presence_of :assigned_groups_count
  validates_numericality_of :assigned_groups_count
  before_validation :update_assigned_groups_count

  has_many :criterion_ta_associations, dependent: :destroy
  has_many :tas, through: :criterion_ta_associations
  has_many :test_groups

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :assessment_id

  validates_presence_of :max_mark
  validates_numericality_of :max_mark, greater_than: 0

  has_many :criteria_assignment_files_joins,
           dependent: :destroy
  has_many :assignment_files,
           through: :criteria_assignment_files_joins
  accepts_nested_attributes_for :criteria_assignment_files_joins, allow_destroy: true

  validate :results_unreleased?
  validate :visible?

  has_many :levels, -> { order(:mark) }, inverse_of: :criterion, dependent: :destroy, autosave: true
  accepts_nested_attributes_for :levels, allow_destroy: true

  def update_assigned_groups_count
    result = criterion_ta_associations.flat_map do |cta|
      cta.ta.get_groupings_by_assignment(assignment)
    end
    self.assigned_groups_count = result.uniq.length
  end

  # Assigns a random TA from a list of TAs specified by +ta_ids+ to each
  # criterion in a list of criteria specified by +criterion_ids+. The criteria
  # must belong to the given assignment +assignment+.
  def self.randomly_assign_tas(criterion_ids, ta_ids, assignment)
    assign_tas(criterion_ids, ta_ids, assignment) do |c_ids, t_ids|
      # Assign TAs in a round-robin fashion to a list of random criteria.
      shuffled_criterion_ids = c_ids.shuffle
      shuffled_criterion_ids.zip(t_ids.cycle).map(&:flatten)
    end
  end

  # Assigns all TAs in a list of TAs specified by +ta_ids+ to each criterion in
  # a list of criteria specified by +criterion_ids+. The criteria must belong
  # to the given assignment +assignment+.
  def self.assign_all_tas(criterion_ids, ta_ids, assignment)
    assign_tas(criterion_ids, ta_ids, assignment) do |c_ids, t_ids|
      c_ids.product(t_ids)
    end
  end

  # Assigns TAs to criteria using a caller-specified block. The block is given
  # a list of criterion IDs and a list of TA IDs and must return a list of
  # criterion-ID-TA-ID pair that represents the TA assignment.
  #
  #   # Assign the TA with ID 3 to the criterion with ID 1 and the TA
  #   # with ID 4 to the criterion with ID 2.
  #   assign_tas([1, 2], [3, 4], a) do |criterion_ids, ta_ids|
  #     criterion_ids.zip(ta_ids)  # => [[1, 3], [2, 4]]
  #   end
  #
  # The criteria must belong to the given assignment +assignment+.
  def self.assign_tas(criterion_ids, ta_ids, assignment)
    ta_ids = Array(ta_ids)

    # Only use IDs that identify existing model instances.
    ta_ids = Ta.where(id: ta_ids).pluck(:id)
    columns = [:criterion_id, :ta_id]
    # Get all existing criterion-TA associations to avoid violating the unique
    # constraint.
    existing_values = CriterionTaAssociation
                      .where(criterion_id: criterion_ids,
                             ta_id: ta_ids)
                      .pluck(:criterion_id, :ta_id)

    # Delegate the assign function to the caller-specified block and remove
    # values that already exist in the database.
    new_values = yield(criterion_ids, ta_ids)
    values = new_values - existing_values

    # Add assessment_id column common to all rows. It is not included above so
    # that the set operation is faster.
    columns << :assessment_id
    values.map { |value| value << assignment.id }
    # TODO replace CriterionTaAssociation.import with
    # CriterionTaAssociation.create when the PG driver supports bulk create,
    # then remove the activerecord-import gem.
    CriterionTaAssociation.import(columns, values, validate: false)

    Grouping.update_criteria_coverage_counts(assignment)
    update_assigned_groups_counts(assignment)
  end

  # Unassigns TAs from groupings. +criterion_ta_ids+ is a list of TA
  # membership IDs that specifies the unassignment to be done. The memberships
  # and groupings must belong to the given assignment +assignment+.
  def self.unassign_tas(criterion_ta_ids, assignment)
    CriterionTaAssociation.where(id: criterion_ta_ids).delete_all

    Grouping.update_criteria_coverage_counts(assignment)
    update_assigned_groups_counts(assignment)
  end

  # Updates the +assigned_groups_count+ field of all criteria that belong to
  # an assignment with ID +assignment_id+.
  def self.update_assigned_groups_counts(assignment)
    counts = CriterionTaAssociation
             .from(
               # subquery
               assignment.criterion_ta_associations
                         .joins(ta: :groupings)
                         .where('groupings.assessment_id': assignment.id)
                         .select('criterion_ta_associations.criterion_id',
                                 'groupings.id')
                         .distinct
             )
             .group('subquery.criterion_id')
             .count

    records = assignment.criteria
                        .pluck_to_hash
                        .map do |h|
      { **h.symbolize_keys, assigned_groups_count: counts[h['id']] || 0 }
    end

    Criterion.upsert_all(records) unless records.empty?
  end

  # When max_mark of criterion is changed, all associated marks should have their mark value scaled to the change.
  def scale_marks
    return unless max_mark_previously_changed? && !previous_changes[:max_mark].first.nil? # if max_mark was not updated

    max_mark_was = previous_changes[:max_mark].first
    # results with specific assignment
    results = Result.includes(submission: :grouping)
                    .where(groupings: { assessment_id: assessment_id })
    all_marks = marks.where.not(mark: nil).where(result_id: results.ids)
    # all associated marks should have their mark value scaled to the change.
    updated_marks = {}
    all_marks.each do |mark|
      updated_marks[mark.id] = mark.scale_mark(max_mark, max_mark_was, update: false)
    end
    unless updated_marks.empty?
      Mark.upsert_all(all_marks.pluck_to_hash.map { |h| { **h.symbolize_keys, mark: updated_marks[h['id'].to_i] } })
    end
    a = Assignment.find(assessment_id)
    updated_results = results.map do |result|
      [result.id, result.get_total_mark(assignment: a)]
    end.to_h
    unless updated_results.empty?
      Result.upsert_all(
        results.pluck_to_hash.map { |h| { **h.symbolize_keys, total_mark: updated_results[h['id'].to_i] } }
      )
    end
    a.assignment_stat.refresh_grade_distribution
  end

  def results_unreleased?
    return true if self.marks.joins(:result).where('results.released_to_students' => true).empty?

    errors.add(:base, 'Cannot update criterion once results are released.')
    false
  end

  private

  # Checks if the criterion is visible to either the ta or the peer reviewer.
  def visible?
    if ta_visible || peer_visible
      true
    else
      errors.add(:base, I18n.t('activerecord.errors.models.criterion.visibility_error'))
      false
    end
  end

  def update_results
    new_results = self.marks.includes(:result).map do |m|
      next if m.mark.nil?
      if m.result.marks.count == 1
        m.result.marking_state = Result::MARKING_STATES[:incomplete]
        m.result.total_mark = nil
      else
        m.result.total_mark = m.result.total_mark - m.mark
      end
      { id: m.result.id, total_mark: m.result.total_mark, marking_state: m.result.marking_state }
    end
    new_results = new_results.compact
    Result.upsert_all(new_results) unless new_results.blank?
  end
end
