# Policy for Automated tests controller.
class AutomatedTestPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :student_interface?, :get_test_runs_students?, :execute_test_run?, to: :student?

  # Only instructor and authorized grader can setup the automated testing.
  def manage?
    check?(:manage_assessments?, role)
  end
end
