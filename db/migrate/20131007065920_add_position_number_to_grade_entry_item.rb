class AddPositionNumberToGradeEntryItem < ActiveRecord::Migration[4.2]
  def self.up
    add_column :grade_entry_items, :position, :integer
  end

  def self.down
    remove_column :grade_entry_items, :position
  end
end
