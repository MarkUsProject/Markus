# Job message policy class
class JobMessagePolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    true
  end
end
