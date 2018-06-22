class TrackAutotestRuns5 < ActiveRecord::Migration[4.2]
  def change
    change_column :test_runs, :queue_len, :bigint
    rename_column :test_runs, :queue_len, :time_to_service_estimate
    rename_column :test_runs, :avg_pop_interval, :time_to_service
  end
end
