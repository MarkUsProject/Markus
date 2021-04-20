class AddAutotestIds < ActiveRecord::Migration[6.0]
  def change
    add_column :assignment_properties, :autotest_settings_id, :integer
    add_column :test_runs, :autotest_test_id, :integer
  end
end
