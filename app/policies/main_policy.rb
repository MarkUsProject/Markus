# Main policy class
class MainPolicy < ApplicationPolicy
  skip_pre_check :role_exists?

  default_rule :manage?

  def manage?
    true
  end
end
