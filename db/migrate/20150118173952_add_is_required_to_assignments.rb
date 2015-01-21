class AddIsRequiredToAssignments < ActiveRecord::Migration
  def change
      add_column :assignments, :is_required, :boolean, :default => "false"
  end
end
