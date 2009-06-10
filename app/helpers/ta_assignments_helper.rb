module TaAssignmentsHelper

  def assign_ta_to_grouping(ta_id, grouping_id)
    ta_membership = TAMembership.new
    ta_membership.user_id = ta_id
    ta_membership.grouping_id = grouping_id
    ta_membership.save
  end

end
