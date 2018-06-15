class AddUnitsToExtraMarks < ActiveRecord::Migration[4.2]
  def self.up
    add_column :extra_marks, :unit, :string
  end

  def self.down
    remove_column :extra_marks, :unit
  end
end
