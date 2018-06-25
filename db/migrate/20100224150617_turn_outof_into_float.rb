class TurnOutofIntoFloat < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :grade_entry_items, :out_of
    add_column :grade_entry_items, :out_of, :float
  end

  def self.down
    remove_column :grade_entry_items, :out_of
    add_column :grade_entry_items, :out_of, :string
  end
end
