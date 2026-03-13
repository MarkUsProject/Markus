namespace :db do
  desc 'Assign TAs to A1 groupings and criteria'
  task ta_assignments: :environment do
    puts 'Assign TAs to A1 groupings and criteria'

    assignment = Assignment.find_by(short_identifier: 'A1')
    return if assignment.nil?

    tas = assignment.course.tas.order(:id)
    return if tas.empty?

    # Assign TAs to groupings (round-robin)
    ta_memberships = assignment.groupings.order(:id).each_with_index.map do |grouping, i|
      { role_id: tas[i % tas.size].id, grouping_id: grouping.id, type: 'TaMembership' }
    end

    Repository.get_class.update_permissions_after do
      TaMembership.joins(:grouping)
                  .where(groupings: { assessment_id: assignment.id })
                  .delete_all
      TaMembership.insert_all(ta_memberships) unless ta_memberships.empty?
    end

    # Enable criteria-based grader assignment
    assignment.assignment_properties.update!(assign_graders_to_criteria: true)

    # Assign TAs to criteria (round-robin)
    criteria_mappings = assignment.criteria.order(:position).each_with_index.map do |criterion, i|
      { criterion_id: criterion.id, ta_id: tas[i % tas.size].id, assessment_id: assignment.id }
    end

    CriterionTaAssociation.where(assessment_id: assignment.id).delete_all
    CriterionTaAssociation.insert_all(criteria_mappings) unless criteria_mappings.empty?

    Grouping.update_criteria_coverage_counts(assignment)
    Criterion.update_assigned_groups_counts(assignment)
  end
end
