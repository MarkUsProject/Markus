class AddPositionNumberToGradeEntryItem < ActiveRecord::Migration
  def self.up
    add_column :grade_entry_items, :position, :integer
  end

  def self.down
    remove_column :grade_entry_items, :position
  end
end
