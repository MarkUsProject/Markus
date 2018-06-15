class AddIsHiddenToGradeEntryForm < ActiveRecord::Migration[4.2]
  def change
    add_column :grade_entry_forms, :is_hidden, :boolean
  end
end
