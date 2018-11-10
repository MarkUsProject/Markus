class AssignmentPolicy < AutotestPolicy
  def run_tests?
    check?(:not_a_ta?) && check?(:enabled?) && check?(:has_test_scripts?) && (!user.student? ||
      (check?(:tokens_released?) && check?(:before_due_date?))
    )
  end

  def enabled?
    record.enable_test && (!user.student? || record.enable_student_tests)
  end

  def has_test_scripts?
    record.select_test_scripts(user).exists?
  end

  def tokens_released?
    Time.current >= record.token_start_date
  end

  def before_due_date?
    !record.submission_rule.can_collect_now?
  end
end
