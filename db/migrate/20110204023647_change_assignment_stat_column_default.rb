class ChangeAssignmentStatColumnDefault < ActiveRecord::Migration[4.2]
  def self.up
    change_column_default(:assignment_stats, :grade_distribution_percentage, nil)
  end

  def self.down
    change_column_default(:assignment_stats, :grade_distribution_percentage,
          "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n")
  end
end
