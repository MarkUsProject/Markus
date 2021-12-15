# Course summary policy class
class CourseSummaryPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    role.instructor?
  end

  def populate?
    true
  end

  def index?
    true
  end
end
