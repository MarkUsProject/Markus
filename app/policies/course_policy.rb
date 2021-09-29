# Policy for courses controller.
class CoursePolicy < ApplicationPolicy
  default_rule :manage?

  def show?
    true
  end

  def index?
    true
  end

  def manage?
    false
  end
end
