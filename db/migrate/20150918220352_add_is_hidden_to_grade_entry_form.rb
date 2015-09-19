class AddIsHiddenToGradeEntryForm < ActiveRecord::Migration
  def change
    add_column :grade_entry_form, :is_hidden, :boolean
  end
end
