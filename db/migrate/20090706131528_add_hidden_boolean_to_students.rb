class AddHiddenBooleanToStudents < ActiveRecord::Migration
  def self.up
    add_column :users, :hidden, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :hidden
  end
end
