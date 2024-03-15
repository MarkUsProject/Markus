# Policy for starter file groups
class StarterFileGroupPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    check?(:manage_assessments?, role)
  end

  def download_file?
    role.instructor? || role.ta?
  end

  def download_files?
    role.instructor? || role.ta?
  end
end
