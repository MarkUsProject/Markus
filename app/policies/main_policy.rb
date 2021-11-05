# Main policy class
class MainPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    true
  end
end
