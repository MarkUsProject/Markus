class AddJsonAutotestSettings < ActiveRecord::Migration[7.0]
  def change
    rename_column :assignment_properties, :autotest_settings_id, :remote_autotest_settings_id
    add_column :assignment_properties, :autotest_settings, :json
    add_column :test_groups, :autotest_settings, :json, null: false, default: {}
  end
end
