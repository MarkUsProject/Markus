class AddAutotestIds < ActiveRecord::Migration[6.0]
  def up
    add_column :assignment_properties, :autotest_settings_id, :integer
    add_column :test_runs, :autotest_test_id, :integer
    add_column :test_runs, :status, :integer, null: false
    remove_column :test_runs, :time_to_service_estimate
    remove_column :test_runs, :time_to_service
  end

  def down
    remove_column :assignment_properties, :autotest_settings_id
    remove_column :test_runs, :autotest_test_id, :integer
    remove_column :test_runs, :status
    add_column :test_runs, :time_to_service_estimate, :integer
    add_column :test_runs, :time_to_service, :integer
  end
end
