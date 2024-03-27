# Policy for starter file groups
class StarterFileGroupPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :download_file?, :download_files?, to: :read?

  def manage?
    check?(:manage_assessments?, role)
  end

  def read?
    role.instructor? || role.ta?
  end
end
