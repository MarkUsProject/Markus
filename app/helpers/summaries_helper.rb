module SummariesHelper
  include SubmissionsHelper
  def get_summaries_table_info(assignment, grader_id=nil)
    if grader_id.nil?
      groupings = assignment.groupings
        .includes(:assignment,
                  :group,
                  :grace_period_deductions,
                  current_submission_used: :results,
                  accepted_student_memberships: :user)
        .select { |g| g.non_rejected_student_memberships.size > 0 }
    else
      ta = Ta.find(grader_id)
      groupings = assignment.groupings
        .includes(:assignment,
                  :group,
                  :grace_period_deductions,
                  current_submission_used: :results,
                  accepted_student_memberships: :user)
        .select do |g|
          g.non_rejected_student_memberships.size > 0 and
          ta.is_assigned_to_grouping?(g.id)
        end
    end

    groupings.map do |grouping|
      g = grouping.attributes
      g[:class_name] = get_any_tr_attributes(grouping)
      g[:group_name] = get_grouping_group_name(assignment, grouping)
      g[:repository] = get_grouping_repository(assignment, grouping)
      g[:commit_date] = get_grouping_commit_date(assignment, grouping)
      g[:marking_state] = get_grouping_marking_state(assignment, grouping)
      g[:grace_credits_used] = get_grouping_grace_credits_used(grouping)
      g[:final_grade] = get_grouping_final_grades(grouping)
      g[:section] = get_grouping_section(grouping)
      g[:criteria] = get_grouping_criteria(assignment, grouping)
      g[:state] = get_grouping_state(grouping)
      g
    end
  end

  def get_grouping_criteria(assignment, grouping)
    # put all criteria in a hash for retrieval
    criteria_hash = Hash.new
    assignment.rubric_criteria.each do |criterion|
      key = 'criterion_' + criterion.id.to_s
      if grouping.has_submission?
        mark = grouping.current_submission_used.get_latest_result.marks.find_by_markable_id(criterion.id)
        if mark.nil? || mark.mark.nil?
          criteria_hash[key] = '-'
        else
          criteria_hash[key] = mark.mark.to_s
        end
      else
        criteria_hash[key] = '-'
      end
    end
    criteria_hash
  end
end
