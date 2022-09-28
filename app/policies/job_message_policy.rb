# Job message policy class
class JobMessagePolicy < ApplicationPolicy
  skip_pre_check :role_exists?

  default_rule :manage?

  def manage?
    true
  end
end
