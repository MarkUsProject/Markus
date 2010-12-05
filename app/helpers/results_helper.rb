module ResultsHelper

  def remark_result_unsubmitted_or_released(remark_result)
    return (remark_result.marking_state == Result::MARKING_STATES[:unmarked] or
            remark_result.released_to_students)
  end

  def results_released_to_students(result)
    submission = result.submission
    if (submission.remark_result)
      return remark_result_unsubmitted_or_released(submission.remark_result)
    else
      return result.released_to_students
    end
  end
  
  def remark_request_submitted_but_unreleased(submission)
    return (submission.remark_result and 
            !remark_result_unsubmitted_or_released(submission.remark_result))
  end

  def can_show_marker_panes(result)
    submission = result.submission
    return (!result.released_to_students or remark_request_submitted_but_unreleased(submission))
  end
  
  def can_show_remark_request_tab_in_student_pane(assignment, current_user, submission)
    return (assignment.allow_remarks and (current_user.student? or (submission.remark_result and submission.remark_result.released_to_students)))
  end
  
  def student_can_edit_remark_request(submission)
    return (!submission.remark_result or submission.remark_result.marking_state == Result::MARKING_STATES[:unmarked])
  end  
  
  def student_can_cancel_remark_request(submission)
    return remark_request_submitted_but_unreleased(submission)
  end
    
  def can_show_remark_request_tab_in_marker_pane(submission)
    return (!student_can_edit_remark_request(submission))
  end
  
end
