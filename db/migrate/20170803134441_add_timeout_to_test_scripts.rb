class AddTimeoutToTestScripts < ActiveRecord::Migration[4.2]
  def change
    add_column :test_scripts, :timeout, :integer, null: false
  end
end
