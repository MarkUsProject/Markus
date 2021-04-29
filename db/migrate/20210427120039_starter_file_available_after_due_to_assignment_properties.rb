class StarterFileAvailableAfterDueToAssignmentProperties < ActiveRecord::Migration[6.0]
  def change
    add_column :assignment_properties, :starter_files_after_due, :boolean, null: false, default: true
  end
end
