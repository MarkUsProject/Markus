class TaMembership < Membership
  validate :must_be_a_ta

  after_create { Repository.get_class.update_permissions }
  after_destroy { Repository.get_class.update_permissions }

  def must_be_a_ta
    if role && !role.is_a?(Ta)
      errors.add('base', 'User must be a ta')
      false
    end
  end

  def self.from_csv(assignment, csv_data, remove_existing)
    if remove_existing
      Repository.get_class.update_permissions_after do
        TaMembership.joins(:grouping)
                    .where(groupings: { assessment_id: assignment.id })
                    .delete_all
      end
    end
    new_ta_memberships = []
    groupings = assignment.groupings.joins(:group).pluck('groups.group_name', :id).to_h
    graders = assignment.course.tas.joins(:user).pluck('users.user_name', :id).to_h
    result = MarkusCsv.parse(csv_data) do |row|
      raise CsvInvalidLineError if row.empty?
      raise CsvInvalidLineError if groupings[row[0]].nil?

      row.drop(1).each do |grader_name|
        unless graders[grader_name].nil?
          new_ta_memberships << {
            role_id: graders[grader_name],
            grouping_id: groupings[row[0]],
            type: 'TaMembership'
          }
        end
      end
    end

    # Dedupe within the CSV and remove already-existing memberships
    new_ta_memberships.uniq!
    unless new_ta_memberships.empty?
      existing_pairs = TaMembership
                       .where(grouping_id: new_ta_memberships.pluck(:grouping_id),
                              role_id: new_ta_memberships.pluck(:role_id))
                       .pluck(:grouping_id, :role_id)
                       .to_set
      new_ta_memberships.reject! { |m| existing_pairs.include?([m[:grouping_id], m[:role_id]]) }
    end

    Repository.get_class.update_permissions_after do
      unless new_ta_memberships.empty?
        TaMembership.insert_all(new_ta_memberships)
      end
    end

    # Recompute criteria associations
    if assignment.assign_graders_to_criteria
      Grouping.update_criteria_coverage_counts(
        assignment,
        new_ta_memberships.pluck(:grouping_id)
      )
    end

    result
  end
end
