class AutomatedTestPolicy < ApplicationPolicy
  default_rule :admin_access?
  alias_rule :update?, :upload_files?, :populate_autotest_manager?, :download_files?, :download_specs?, :upload_specs?, :manage?, to: :manage_test?
  alias_rule :student_interface?, :get_test_runs_students?, :execute_test_run?, to: :student_access?

  def manage_test?
    user.admin? || (user.ta? && allowed_to?(:manage_assignments?, with: GraderPermissionPolicy))
  end

  def student_access?
    user.student?
  end

  def admin_access?
    user.admin?
  end
end
