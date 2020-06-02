class CourseSummariesPolicy < ApplicationPolicy
  def index?
    user.admin? || user.ta?
  end

  def download_csv_grades_report?
    user.admin? || (user.ta? && allowed_to?(:download_grades_report?, with: GraderPermissionsPolicy))
  end
end
