class AddBonusToGradeEntryItems < ActiveRecord::Migration[4.2]
  def change
  	add_column :grade_entry_items, :bonus, :boolean, :default => false
  end
end
