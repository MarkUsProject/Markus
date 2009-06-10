class Ta < User
  SESSION_TIMEOUT = USER_TA_SESSION_TIMEOUT
  CSV_UPLOAD_ORDER = USER_TA_CSV_UPLOAD_ORDER  

  
  def memberships_for_assignment(assignment_id)
    assignment = Assignment.find(assignment_id)
    return assignment.ta_memberships.find_all_by_user_id(id)
  end
 
  def is_assigned_to_grouping?(grouping_id)
    grouping = Grouping.find(grouping_id)
    return grouping.ta_memberships.find_all_by_user_id(id).size > 0
  end
end
