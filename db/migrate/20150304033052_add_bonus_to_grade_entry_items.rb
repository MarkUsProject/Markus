class AddBonusToGradeEntryItems < ActiveRecord::Migration
  def change
  	add_column :grade_entry_items, :bonus, :boolean, :default => false
  end
end
