# The abstract base class that defines common behavior for all types of
# criterion.
class Criterion < ActiveRecord::Base
  self.abstract_class = true

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
