# The abstract base class that defines common behavior for all types of
# criterion.
class Criterion < ActiveRecord::Base
  self.abstract_class = true

  # Assigns a random TA from a list of TAs specified by +ta_ids+ to each
  # criterion in a list of criteria specified by +criterion_ids+. The criteria
  # must belong to the given assignment +assignment+.
  def self.randomly_assign_tas(criterion_ids, ta_ids, assignment)
    assign_tas(criterion_ids, ta_ids, assignment) do |criterion_ids, ta_ids|
      # Assign TAs in a round-robin fashion to a list of random criteria.
      criterion_ids.shuffle.zip(ta_ids.cycle)
    end
  end

  # Assigns all TAs in a list of TAs specified by +ta_ids+ to each criterion in
  # a list of criteria specified by +criterion_ids+. The criteria must belong
  # to the given assignment +assignment+.
  def self.assign_all_tas(criterion_ids, ta_ids, assignment)
    assign_tas(criterion_ids, ta_ids, assignment) do |criterion_ids, ta_ids|
      # Get the Cartesian product of criterion IDs and TA IDs.
      criterion_ids.product(ta_ids)
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
    criterion_ids, ta_ids = Array(criterion_ids), Array(ta_ids)
    criterion_class = assignment.criterion_class
    criterion_type = criterion_class.name

    # Only use IDs that identify existing model instances.
    ta_ids = Ta.where(id: ta_ids).pluck(:id)
    criterion_ids = criterion_class.where(id: criterion_ids).pluck(:id)

    columns = [:criterion_id, :ta_id]
    # Get all existing criterion-TA associations to avoid violating the unique
    # constraint.
    # TODO replace this with Membership.pluck when migrated to Rails 4.
    existing_values = CriterionTaAssociation.select(columns)
      .where(criterion_id: criterion_ids, ta_id: ta_ids,
             criterion_type: criterion_type)
      .map { |criterion_ta| [criterion_ta.criterion_id, criterion_ta.ta_id] }
    # Delegate the assign function to the caller-specified block and remove
    # values that already exist in the database.
    values = yield(criterion_ids, ta_ids) - existing_values
    # Add columns that are common to all rows. They are not included above so
    # that the set operation is faster.
    columns << :criterion_type << :assignment_id
    values.map { |value| value << criterion_type << assignment.id }
    # TODO replace CriterionTaAssociation.import with
    # CriterionTaAssociation.create when the PG driver supports bulk create,
    # then remove the activerecord-import gem.
    CriterionTaAssociation.import(columns, values, validate: false)

    Grouping.update_criteria_coverage_counts(assignment)
    update_assigned_groups_counts(assignment, criterion_ids)
  end

  # Unassigns TAs from groupings. +criterion_ta_ids+ is a list of TA
  # membership IDs that specifies the unassignment to be done. +criterion_ids+
  # is a list of grouping IDs involved in the unassignment. The memberships
  # and groupings must belong to the given assignment +assignment+.
  def self.unassign_tas(criterion_ta_ids, criterion_ids, assignment)
    CriterionTaAssociation.delete_all(id: criterion_ta_ids)

    Grouping.update_criteria_coverage_counts(assignment)
    update_assigned_groups_counts(assignment, criterion_ids)
  end

  # Updates the +assigned_groups_count+ field of all criteria that belong to
  # an assignment with ID +assignment_id+.
  def self.update_assigned_groups_counts(assignment, criterion_ids = nil)
    # Sanitize the IDs in the input.
    criterion_ids_str = Array(criterion_ids)
      .map { |criterion_id| connection.quote(criterion_id) }
      .join(',')
    criterion_class = assignment.criterion_class
    # TODO replace this raw SQL with dynamic SET clause with Active Record
    # language when the latter supports subquery in the SET clause.
    criterion_class.connection.execute(<<-UPDATE_SQL)
      UPDATE #{criterion_class.table_name} AS c SET assigned_groups_count =
        (SELECT count(DISTINCT g.id) FROM memberships AS m
          INNER JOIN groupings AS g ON m.grouping_id = g.id
          INNER JOIN criterion_ta_associations AS ct ON m.user_id = ct.ta_id
          WHERE g.assignment_id = #{assignment.id}
            AND ct.criterion_id = c.id AND ct.assignment_id = c.assignment_id
            AND m.type = 'TaMembership')
        WHERE assignment_id = #{assignment.id}
          #{"AND id IN (#{criterion_ids_str})" unless criterion_ids_str.empty?}
    UPDATE_SQL
  end
end
