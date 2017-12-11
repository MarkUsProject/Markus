module SummariesHelper
  include SubmissionsHelper
  def get_summaries_table_info(assignment, grader_id=nil)
    if grader_id.nil?
      groupings = assignment.groupings
                      .includes(:assignment,
                                :group,
                                :accepted_students,
                                :inviter,
                                :tas,
                                current_result: :marks,
                                )
    else
      groupings = assignment.groupings
        .includes(:assignment,
                  :group,
                  :accepted_students,
                  :inviter,
                  current_result: :marks)
        .joins(:memberships)
        .where('memberships.user_id': grader_id)
    end

    data = []
    groupings.find_each do |grouping|
      g = {}
      g[:name] = grouping.get_group_name
      g[:section] = grouping.section
      g[:tas] = grader_id ? [] : grouping.tas.map(&:user_name)

      result = grouping.current_result
      if result.nil?
        g[:name_url] = ''
        g[:final_grade] = ''
        g[:criteria] = {}
      else
        g[:name_url] = get_grouping_name_url(grouping, result)
        g[:final_grade] = grouping.final_grade(result)
        g[:criteria] = get_grouping_criteria(grouping)
      end
      data << g
    end
    data
  end

  def get_grouping_criteria(grouping)
    # put all criteria in a hash for retrieval
    criteria_hash = Hash.new
    unless grouping.current_result.nil?
      grouping.current_result.marks.each do |mark|
        key = "criterion_#{mark.markable_type}_#{mark.markable_id}"
        criteria_hash[key] = mark.mark
      end
    end
    criteria_hash
  end
end
