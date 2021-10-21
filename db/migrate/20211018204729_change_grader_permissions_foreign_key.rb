class ChangeGraderPermissionsForeignKey < ActiveRecord::Migration[6.1]
  def change
    add_reference :grader_permissions, :role, foreign_key:true
    remove_column :grader_permissions, :users_id, type: :integer
  end
end
