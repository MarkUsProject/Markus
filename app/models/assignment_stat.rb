class AssignmentStat < ActiveRecord::Base

  belongs_to :assignment

  # Update the cached grade distribution
  def refresh_grade_distribution
    self.grade_distribution_percentage =
      self.assignment.grade_distribution_as_percentage.to_csv
    self.save
  end

  # Returns an array containing the grade distribution as percentage
  # Used by Chart.js to draw the graphs
  def grade_distribution_array
    if self.grade_distribution_percentage
      grade_distribution_percentage.parse_csv.map(&:to_i)
    else
      # Default, empty distribution
      '[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]'
    end
  end
end
