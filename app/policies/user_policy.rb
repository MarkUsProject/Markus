class UserPolicy < ActionPolicy::Base
  def manage? # this is the default rule
    user.admin?
  end

  def destroy?
    false
  end
end
