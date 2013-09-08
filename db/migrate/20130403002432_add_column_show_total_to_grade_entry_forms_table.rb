class AddColumnShowTotalToGradeEntryFormsTable < ActiveRecord::Migration
  def self.up
    add_column :grade_entry_forms, :show_total, :boolean
  end

  def self.down
    remove_column :grade_entry_forms, :show_total
  end
end
