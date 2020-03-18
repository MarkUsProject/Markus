class TaMembership < Membership
  validate :must_be_a_ta

  after_create   { Repository.get_class.update_permissions }
  after_destroy  { Repository.get_class.update_permissions }

 def must_be_a_ta
   if user && !user.is_a?(Ta)
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
    groupings = Hash[
      assignment.groupings.joins(:group).pluck('groups.group_name', :id)
    ]
    graders = Hash[Ta.pluck(:user_name, :id)]
    result = MarkusCsv.parse(csv_data.read) do |row|
      raise CsvInvalidLineError if row.empty?
      raise CsvInvalidLineError if groupings[row[0]].nil?

      row.drop(1).each do |grader_name|
        unless graders[grader_name].nil?
          new_ta_memberships << TaMembership.new(
            grouping_id: groupings[row[0]],
            user_id: graders[grader_name]
          )
        end
      end
    end
    Repository.get_class.update_permissions_after do
      TaMembership.import new_ta_memberships, validate: false, on_duplicate_key_ignore: true
    end

    # Recompute criteria associations
    if assignment.assign_graders_to_criteria
      Grouping.update_criteria_coverage_counts(
        assignment,
        new_ta_memberships.map { |x| x[:grouping_id] }
      )
    end

    result
  end
end
