# Policy for Exam templates controller.
class ExamTemplatePolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :index?, :create?, :destroy?, :update?, :generate?,
             :split?, :add_fields?, :view_logs?, :download?, :download_generate?,
             :download_raw_split_file?, :show_cover?, to: :modify?

  def manage?
    user.admin?
  end

  # Only admin and authorized grader can manage or modify exam templates
  def modify?
    user.admin? || (user.ta? && allowed_to?(:manage_exam_templates?, with: GraderPermissionPolicy))
  end
end
