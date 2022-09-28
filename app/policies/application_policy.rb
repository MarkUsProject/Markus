# Application policy class
class ApplicationPolicy < ActionPolicy::Base
  authorize :user, optional: true
  authorize :role, optional: true
  authorize :real_user
  authorize :real_role, optional: true

  alias_rule :index?, :create?, :new?, to: :manage?

  pre_check :role_exists?
  pre_check :view_hidden_course?
  pre_check :role_is_hidden?

  skip_pre_check :role_is_hidden?, only: :role_is_switched?

  # unless overridden, do not allow access by default
  def manage?
    false
  end

  # pre checks

  def role_exists?
    deny! if role.nil?
  end

  def view_hidden_course?
    deny! if role&.student? && role.course.is_hidden
  end

  def role_is_hidden?
    deny! if role&.hidden
  end

  # policies used to render menu bars (visible everywhere)

  def view_instructor_subtabs?
    role && check?(:manage_assessments?, role)
  end

  def view_ta_subtabs?
    role&.ta?
  end

  def view_student_subtabs?
    role&.student?
  end

  def view_admin_subtabs?
    user&.admin_user?
  end

  def view_sub_sub_tabs?
    role&.instructor? || role&.ta?
  end

  # checks usable for all policies

  delegate :admin_user?, to: :real_user

  delegate :instructor?, to: :role

  delegate :ta?, to: :role

  delegate :student?, to: :role

  def role_is_switched?
    real_user != user
  end
end
