class AddScannedExamToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :scanned_exam, :boolean, null: false, default: false
  end
end
