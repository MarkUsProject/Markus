class AddEnableTestToAssignment < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :enable_test, :boolean, :default => false, :null =>false
  end

  def self.down
    remove_column :assignments, :enable_test
  end
end
