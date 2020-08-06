# Policy for Course summaries controller.
class CourseSummaryPolicy < ApplicationPolicy
  alias_rule :index?, :populate?, to: :view_course_summary?

  # Only admin and authorized grader can view course summary.
  def view_course_summary?
    user.admin? || (user.ta? && allowed_to?(:download_csv_grades_report?)) || user.student?
  end

  def download_csv_grades_report?
    user.admin? || (user.ta? && allowed_to?(:manage_course_grades?, with: GraderPermissionPolicy))
  end

  def marking_schemes?
    check?(:download_csv_grades_report?)
  end
end
