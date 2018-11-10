class GroupingPolicy < AutotestPolicy
  def run_tests?
    check?(:not_a_ta?) && (!user.student? ||
      (check?(:member?) && check?(:not_in_progress?) && check?(:tokens_available?))
    )
  end

  def member?
    record.accepted_students.include?(user)
  end

  def not_in_progress?
    !record.student_test_run_in_progress?
  end

  def tokens_available?
    record.test_tokens > 0 || record.assignment.unlimited_tokens
  end
end
