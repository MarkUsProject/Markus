class ExamTemplatePolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :index?, :create?, :destroy?, :update?, :generate?,
             :split?, :add_fields?, :view_logs?, :download?, :download_generate?,
             :download_raw_split_file?, to: :modify?

  def manage?
    user.admin?
  end

  def modify?
    user.admin? || (user.ta? && GraderPermission.find_by(user_id: user.id).manage_exam_templates)
  end
end
