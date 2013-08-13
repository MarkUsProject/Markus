module ResultsHelper

  def remark_result_unsubmitted_or_released(remark_result)
    return (remark_result.marking_state == Result::MARKING_STATES[:unmarked] or
            remark_result.released_to_students)
  end

  def can_show_remark_request_tab_in_student_pane(assignment, current_user, submission)
    if (assignment.allow_remarks)
      if (submission.remark_result and submission.remark_result.released_to_students)
        return true
      else
        return (current_user.student?)
      end
    else
      return false
    end
  end

  def student_can_edit_remark_request(submission)
    return (!submission.remark_result or
            submission.remark_result.marking_state == Result::MARKING_STATES[:unmarked])
  end

  def can_show_remark_request_tab_in_marker_pane(submission)
    return (!student_can_edit_remark_request(submission))
  end

  # ATE_SIMPLE_UI: this is temporary
  def test_result_available(assignment, grouping)
    test_script_results = TestScriptResult.find_all_by_grouping_id(grouping.id)
    return (assignment.enable_test) && (!test_script_results.empty?)
  end
end
