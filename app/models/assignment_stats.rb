require 'fastercsv'
class AssignmentStats < ActiveRecord::Base

  belongs_to  :assignment

  # Update the cached grade distribution
  def refresh
    self.grade_distribution_percentage = self.assignment.grade_distribution_as_percentage.to_csv
    self.save
  end
end
