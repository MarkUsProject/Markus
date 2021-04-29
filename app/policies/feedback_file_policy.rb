# Policy for feedback_files_controller
class FeedbackFilePolicy < ApplicationPolicy
  default_rule :get?

  def get?
    if user.admin? || user.ta?
      return true
    end
    feedback_file = record
    feedback_file.test_run.user.id == user.id
  end
end
