# The abstract base class that defines common behavior for all types of
# criterion.
class Criterion < ApplicationRecord
  after_update :scale_marks

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :assignment_id

  validates_presence_of :max_mark
  validates_numericality_of :max_mark, greater_than: 0

  has_many :criteria_assignment_files_joins,
           as: :criterion,
           dependent: :destroy
  has_many :assignment_files,
           through: :criteria_assignment_files_joins
  accepts_nested_attributes_for :criteria_assignment_files_joins, allow_destroy: true

  self.abstract_class = true

  # Assigns a random TA from a list of TAs specified by +ta_ids+ to each
  # criterion in a list of criteria specified by +criterion_ids_types+. The criteria
  # must belong to the given assignment +assignment+.
  def self.randomly_assign_tas(criterion_ids_types, ta_ids, assignment)
    assign_tas(criterion_ids_types, ta_ids, assignment) do |criterion_ids, criterion_types, ta_ids|
      # Assign TAs in a round-robin fashion to a list of random criteria.
      crit_ids_and_types = criterion_ids.zip(criterion_types).shuffle
      crit_ids_and_types.zip(ta_ids.cycle).map &:flatten
    end
  end

  # Assigns all TAs in a list of TAs specified by +ta_ids+ to each criterion in
  # a list of criteria specified by +criterion_ids_types+. The criteria must belong
  # to the given assignment +assignment+.
  def self.assign_all_tas(criterion_ids_types, ta_ids, assignment)
    assign_tas(criterion_ids_types, ta_ids, assignment) do |criterion_ids, criterion_types, ta_ids|
      crit_ids_and_types = criterion_ids.zip(criterion_types)
      # Need to call Array#flatten because after the second product each element has
      # the form [[id, type], ta_id].
      crit_ids_and_types.product(ta_ids).map &:flatten
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
  def self.assign_tas(criterion_ids_types, ta_ids, assignment)
    criterion_ids_in = criterion_ids_types.map { |id_type| id_type[0] }
    criterion_types = criterion_ids_types.map { |id_type| id_type[1] }
    ta_ids = Array(ta_ids)

    # Only use IDs that identify existing model instances.
    ta_ids = Ta.where(id: ta_ids).pluck(:id)
    criteria = assignment.get_criteria(:ta)
                         .select { |crit| criterion_ids_types.include? [crit.id, crit.class.to_s] }
    columns = [:criterion_id, :criterion_type, :ta_id]
    # Get all existing criterion-TA associations to avoid violating the unique
    # constraint.
    existing_values = CriterionTaAssociation
                      .where(criterion_id: criteria.map(&:id),
                             ta_id: ta_ids)
                      .pluck(:criterion_id, :criterion_type, :ta_id)

    # Delegate the assign function to the caller-specified block and remove
    # values that already exist in the database.
    new_values = yield(criteria.map(&:id), criteria.map { |c| "#{c.class}" }, ta_ids)
    values = new_values - existing_values

    # Add assignment_id column common to all rows. It is not included above so
    # that the set operation is faster.
    columns << :assignment_id
    values.map { |value| value << assignment.id }
    # TODO replace CriterionTaAssociation.import with
    # CriterionTaAssociation.create when the PG driver supports bulk create,
    # then remove the activerecord-import gem.
    CriterionTaAssociation.import(columns, values, validate: false)

    Grouping.update_criteria_coverage_counts(assignment)
    criterion_ids_by_type = {}
    %w(RubricCriterion FlexibleCriterion CheckboxCriterion).each do |type|
      criterion_ids_by_type[type] =
        criterion_ids_in.zip(criterion_types)
                        .select { |_, crit_type| crit_type == type}
                        .map { |crit_id, _| crit_id }
    end
    update_assigned_groups_counts(assignment)
  end

  # Unassigns TAs from groupings. +criterion_ta_ids+ is a list of TA
  # membership IDs that specifies the unassignment to be done. +criterion_ids+
  # is a list of grouping IDs involved in the unassignment. The memberships
  # and groupings must belong to the given assignment +assignment+.
  def self.unassign_tas(criterion_ta_ids, criterion_ids_by_type, assignment)
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
                         .where('groupings.assignment_id': assignment.id)
                         .select('criterion_ta_associations.criterion_id',
                                 'criterion_ta_associations.criterion_type',
                                 'groupings.id')
                         .distinct
             )
             .group('subquery.criterion_id', 'subquery.criterion_type')
             .count

    [RubricCriterion, FlexibleCriterion, CheckboxCriterion].each do |klass|
      records = klass.where(assignment_id: assignment.id)
                     .pluck_to_hash
                     .map do |h|
        { **h.symbolize_keys, assigned_groups_count: counts[[h['id'], klass.to_s]] || 0 }
      end
      unless records.empty?
        klass.upsert_all(records)
      end
    end
  end

  # When max_mark of criterion is changed, all associated marks should have their mark value scaled to the change.
  def scale_marks
    return unless max_mark_previously_changed? && !previous_changes[:max_mark].first.nil? # if max_mark was not updated

    max_mark_was = previous_changes[:max_mark].first
    # results with specific assignment
    results = Result.includes(submission: :grouping)
                    .where(groupings: { assignment_id: assignment_id })
    all_marks = marks.where.not(mark: nil).where(result_id: results.ids)
    # all associated marks should have their mark value scaled to the change.
    updated_marks = all_marks.map do |mark|
      { mark.id => mark.scale_mark(max_mark, max_mark_was, update: false) }
    end
    unless updated_marks.empty?
      Mark.upsert_all(all_marks.pluck_to_hash.map { |h| { **h.symbolize_keys, mark: updated_marks[h['id'].to_i] } })
    end
    a = Assignment.find(assignment_id)
    updated_results = results.map do |result|
      { result.id => result.get_total_mark(assignment: a) }
    end
    unless updated_results.empty?
      Result.upsert_all(
        results.pluck_to_hash.map { |h| { **h.symbolize_keys, total_mark: updated_results[h['id'].to_i] } }
      )
    end
    a.assignment_stat.refresh_grade_distribution
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
end
