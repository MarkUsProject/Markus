# Student policy class
class StudentPolicy < RolePolicy
  default_rule :instructor?
  alias_rule :update_mailer_settings?, to: :student?
  alias_rule :update_settings?, to: :settings?
  authorize :assignment, :grouping, :submission, optional: true

  def run_tests?
    allowed = ![assignment, grouping, submission].compact.empty?
    unless assignment.nil?
      allowed &&= check?(:tokens_released?, assignment) && check?(:student_tests_enabled?, assignment)
    end
    unless grouping.nil?
      allowed &&= check?(:member?, grouping) &&
                  check?(:not_in_progress?, grouping) &&
                  check?(:tokens_available?, grouping) &&
                  check?(:before_due_date?, grouping)
    end
    allowed &&= check?(:before_release?, submission) unless submission.nil?
    allowed
  end

  def manage_submissions?
    false
  end

  def manage_assessments?
    false
  end

  def settings?
    role.student?
  end

  def manage_role_status?
    role.instructor?
  end
end
