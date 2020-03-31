class AssignmentStat < ApplicationRecord

  belongs_to :assignment, inverse_of: :assignment_stat, foreign_key: :assessment_id

  # Update the cached grade distribution
  def refresh_grade_distribution
    self.grade_distribution_percentage =
      self.assignment.grade_distribution_array.to_csv
    self.save
  end

  # Returns an array containing the grade distribution as percentage
  # Used by Chart.js to draw the graphs
  def grade_distribution_array
    if self.grade_distribution_percentage
      grade_distribution_percentage.parse_csv.map(&:to_i)
    else
      # Default, empty distribution
      Array.new(20) { 0 }
    end
  end
end
