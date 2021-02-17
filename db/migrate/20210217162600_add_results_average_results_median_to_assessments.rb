class AddResultsAverageResultsMedianToAssessments < ActiveRecord::Migration[6.0]
  def change
    add_column :assessments, :results_average, :float
    add_column :assessments, :results_median, :float
  end
end
