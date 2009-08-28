class AddUnitsToExtraMarks < ActiveRecord::Migration
  def self.up
    add_column :extra_marks, :unit, :string
  end

  def self.down
    remove_column :extra_marks, :unit
  end
end
