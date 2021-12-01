# Application policy class
class ApplicationPolicy < ActionPolicy::Base
  authorize :user, optional: true
  authorize :role, optional: true
  authorize :real_user
  authorize :real_role, optional: true

  alias_rule :index?, :create?, :new?, to: :manage?

  pre_check :role_exists?

  # unless overridden, do not allow access by default
  def manage?
    false
  end

  # pre checks

  def role_exists?
    deny! if role.nil?
  end

  # policies used to render menu bars (visible everywhere)

  def view_admin_subtabs?
    check?(:manage_assessments?, role)
  end

  def view_ta_subtabs?
    role.ta?
  end

  def view_student_subtabs?
    role.student?
  end

  def view_sub_sub_tabs?
    role.admin? || role.ta?
  end

  # checks usable for all policies

  def admin?
    role.admin?
  end

  def ta?
    role.ta?
  end

  def student?
    role.student?
  end

  def role_is_switched?
    real_user != user
  end
end
