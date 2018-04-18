class UserPolicy < ApplicationPolicy

  def create?
    self.user.admin?
  end

  def update?
    self.user.admin?
  end

end
