# The abstract base class that defines common behavior for all types of
# criterion.
class Criterion < ActiveRecord::Base
  self.abstract_class = true

  # Updates the +assigned_groups_count+ field of all criteria that belong to
  # an assignment with ID +assignment_id+.
  def self.update_assigned_groups_counts(assignment_id)
    # Sanitize the ID in the input.
    assignment_id = connection.quote(assignment_id)
    # TODO replace this raw SQL with dynamic SET clause with Active Record
    # language when the latter supports subquery in the SET clause.
    connection.execute(<<-UPDATE_SQL)
      UPDATE #{table_name} AS c SET assigned_groups_count =
        (SELECT count(DISTINCT g.id) FROM memberships AS m
          INNER JOIN groupings AS g ON m.grouping_id = g.id
          INNER JOIN criterion_ta_associations AS ct ON m.user_id = ct.ta_id
          WHERE g.assignment_id = #{assignment_id}
            AND ct.criterion_id = c.id AND ct.assignment_id = c.assignment_id
            AND m.type = 'TaMembership')
        WHERE assignment_id = #{assignment_id}
    UPDATE_SQL
  end
end
