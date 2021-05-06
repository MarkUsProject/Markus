# Policy for FeedbackFilesController
class FeedbackFilePolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    feedback_file = record
    grouping = feedback_file.grouping

    if user.student?
      # Check whether the user is part of the associated group
      return false if grouping.membership_status(user).nil?

      # Students can always view feedback files for student-run tests.
      # For instructor-run tests or submission-associated feedback files, the result
      # must be released.
      if feedback_file.test_group_result&.test_run&.user&.student?
        true
      elsif feedback_file.submission_id.nil?
        grouping.current_result.released_to_students
      else
        feedback_file.submission.current_result.released_to_students
      end
    elsif user.ta?
      grouping.tas.pluck(:id).include? user.id
    else  # user.admin?
      true
    end
  end
end
