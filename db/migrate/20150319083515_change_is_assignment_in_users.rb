class ChangeIsAssignmentInUsers < ActiveRecord::Migration[4.2]
  def up
    change_column :marking_weights, :is_assignment, :boolean, null: false
  end

  def down
  end
end
