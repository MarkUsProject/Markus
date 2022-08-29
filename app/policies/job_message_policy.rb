# Job message policy class
class JobMessagePolicy < ApplicationPolicy
  skip_pre_check :role_exists?
  skip_pre_check :view_hidden_course?

  default_rule :manage?

  def manage?
    true
  end
end
