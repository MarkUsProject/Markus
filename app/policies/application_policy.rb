class ApplicationPolicy < ActionPolicy::Base
  # make :manage? a real catch-all
  def index?
    manage?
  end
  def create?
    manage?
  end
end
