class AddScannedExamToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :scanned_exam, :boolean, null: false, default: false
  end
end
