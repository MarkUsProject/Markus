# Policy for FeedbackFilesController
class FeedbackFilePolicy < ApplicationPolicy
  def show?
    feedback_file = record
    grouping = feedback_file.grouping

    if role.student?
      # Check whether the role is part of the associated group
      return false if grouping.membership_status(role).nil?

      # Students can always view feedback files for student-run tests.
      # For instructor-run tests or submission-associated feedback files, the result
      # must be released.
      if feedback_file.test_group_result&.test_run&.role&.student?
        true
      elsif feedback_file.submission_id.nil?
        grouping.current_result.released_to_students
      else
        feedback_file.submission.current_result.released_to_students
      end
    elsif role.ta?
      grouping.tas.ids.include? role.id
    else # role.instructor?
      true
    end
  end
end
