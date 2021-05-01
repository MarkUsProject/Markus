# Policy for feedback_files_controller
class FeedbackFilePolicy < ApplicationPolicy
  default_rule :get?

  def get?
    if user.admin? || user.ta?
      return true
    end
    feedback_file = record

    if feedback_file.submission
      return feedback_file.submission.grouping.students.exists?(user.id)
    end
    feedback_file.test_run.user.id == user.id
  end
end
