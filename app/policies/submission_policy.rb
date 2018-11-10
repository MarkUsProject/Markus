class SubmissionPolicy < AutotestPolicy
  def run_tests?
    check?(:not_a_ta?) && check?(:before_release?)
  end

  def before_release?
    !record.current_result.released_to_students
  end
end
