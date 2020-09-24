# Application policy class
class ApplicationPolicy < ActionPolicy::Base
  # make :manage? a real catch-all
  def index?
    manage?
  end
  def create?
    manage?
  end

  # unless overridden, do not allow access by default
  def manage?
    false
  end

  # policies used to render menu bars (visible everywhere)

  def view_admin_subtabs?
    check?(:manage_assessments?, user)
  end

  def view_ta_subtabs?
    user.ta?
  end

  def view_student_subtabs?
    user.student?
  end

  def view_sub_sub_tabs?
    user.admin? || user.ta?
  end

  # checks usable for all policies

  def admin?
    user.admin?
  end

  def ta?
    user.ta?
  end

  def student?
    user.student?
  end
end
