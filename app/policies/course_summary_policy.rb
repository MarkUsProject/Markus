class CourseSummaryPolicy < ApplicationPolicy
  alias_rule :index?, :populate?, to: :view_course_summary?
  def view_course_summary?
    record.admin? || (record.ta? &&
        (allowed_to?(:download_csv_grades_report?) || allowed_to?(:marking_schemes?))) || (user.student?)
  end

  def download_csv_grades_report?
    record.admin? || (record.ta? && allowed_to?(:download_grades_report?, with: GraderPermissionPolicy))
  end

  def marking_schemes?
    record.admin? || (record.ta? && allowed_to?(:manage_marking_schemes?, with: GraderPermissionPolicy))
  end
end
