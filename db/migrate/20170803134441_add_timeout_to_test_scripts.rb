class AddTimeoutToTestScripts < ActiveRecord::Migration
  def change
    add_column :test_scripts, :timeout, :integer, null: false
  end
end
