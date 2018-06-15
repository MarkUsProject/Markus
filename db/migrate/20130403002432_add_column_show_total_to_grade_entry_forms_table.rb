class AddColumnShowTotalToGradeEntryFormsTable < ActiveRecord::Migration[4.2]
  def self.up
    add_column :grade_entry_forms, :show_total, :boolean
  end

  def self.down
    remove_column :grade_entry_forms, :show_total
  end
end
