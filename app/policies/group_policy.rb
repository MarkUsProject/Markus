class GroupPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :create?, :destroy?, :delete_rejected?, :disinvite_member?, :invite_member?, :accept_invitation?,
             :decline_invitation?, :download_starter_file?, to: :student_manage?
  def student_manage?
    user.student?
  end

  def manage?
    user.admin?
  end
end
