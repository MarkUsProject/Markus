module GroupsHelper

  def assign_tas_to_groupings(grouping_ids, ta_id_array)
    result = {}
    grouping_ids.each do |g|
      grouping = Grouping.find(g)
      grouping.add_tas(ta_id_array)
      result[grouping.id] = construct_table_row(grouping)
    end
    return result;
  end
  
  def unassign_tas_to_groupings(grouping_ids, ta_id_array) 
    result = {}
    grouping_ids.each do |g|
      grouping = Grouping.find(g)
      grouping.remove_tas(ta_id_array)
      result[grouping.id] = construct_table_row(grouping)
    end
    return result
  end
  
  def construct_table_row(grouping)
      table_row = {}

      table_row[:id] = grouping.id
      
      table_row[:name] = render_to_string :partial => "groups/table_row/name", :locals => {:grouping => grouping, :assignment => @assignment}
      
      table_row[:members] = render_to_string :partial => "groups/table_row/members", :locals => {:grouping => grouping}
      
      table_row[:graders] = render_to_string :partial => "groups/table_row/graders", :locals => {:grouping => grouping}
      
      table_row[:valid] = render_to_string :partial => "groups/table_row/valid", :locals => {:grouping => grouping}
      
      table_row[:filter_valid] = grouping.is_valid?
      table_row[:filter_assigned] = grouping.ta_memberships.size > 0

      return table_row
  end
end
