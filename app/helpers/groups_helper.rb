module GroupsHelper

  
  def randomly_assign_graders(grader_ids, grouping_ids)
    # Shuffle the groupings
    groupings = Grouping.find(:all, :conditions => { :id => grouping_ids })
    groupings = groupings.sort_by{rand}
    # Now, deal them out like cards...
    groupings.each_with_index do |grouping, index|
      # Choose the next grader to deal out to...
      grader = grader_ids[index % grader_ids.size]
      grouping.add_ta_by_id(grader) 
    end
  end
  
  def assign_tas_to_groupings(grouping_ids, ta_id_array)
    result = {}
    grouping_ids.each do |g|
      grouping = Grouping.find(g)
      grouping.add_tas(ta_id_array)
      result[grouping.id] = construct_table_row(grouping, grouping.assignment)
    end
    return result;
  end
  
  def unassign_tas_to_groupings(grouping_ids, ta_id_array) 
    result = {}
    grouping_ids.each do |g|
      grouping = Grouping.find(g)
      grouping.remove_tas(ta_id_array)
      result[grouping.id] = construct_table_row(grouping, grouping.assignment)
    end
    return result
  end
  
  def construct_table_rows(groupings, assignment)
    result = {}
    groupings.each do |grouping|
      result[grouping.id] = construct_table_row(grouping, assignment)
    end
    return result
  end
  
  def construct_table_row(grouping, assignment)
      table_row = {}

      table_row[:id] = grouping.id
      table_row[:filter_table_row_contents] = render_to_string :partial => 'groups/table_row/filter_table_row', :locals => {:grouping => grouping, :assignment => assignment}
      
      table_row[:name] = grouping.group.group_name
      
      table_row[:members] = grouping.accepted_students.collect{ |student| student.user_name}.join(',')

      table_row[:graders] = grouping.get_ta_names.join(',')

      table_row[:valid] = grouping.is_valid?
      table_row[:filter_valid] = grouping.is_valid?
      table_row[:filter_assigned] = grouping.ta_memberships.size > 0

      return table_row
  end
end
