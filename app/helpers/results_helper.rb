module ResultsHelper

  def remark_result_unsubmitted_or_released(remark_result)
    remark_result.marking_state == Result::MARKING_STATES[:unmarked] ||
      remark_result.released_to_students
  end

  def can_show_remark_request_tab_in_student_pane(assignment,
                                                  current_user,
                                                  submission)
    if assignment.allow_remarks
      if submission.remark_result &&
         submission.remark_result.released_to_students
        return true
      else
        return current_user.student?
      end
    else
      false
    end
  end

  def student_can_edit_remark_request(submission)
    !submission.remark_result ||
      submission.remark_result.marking_state ==
        Result::MARKING_STATES[:unmarked]
  end

  def can_show_remark_request_tab_in_marker_pane(submission)
    !student_can_edit_remark_request(submission)
  end

  def can_show_test_results_tab?(assignment, submission)
    submission.test_results && assignment.enable_test
  end
end
