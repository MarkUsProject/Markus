class ChangeGraderPermissionsForeignKey < ActiveRecord::Migration[6.1]
  def change
    add_reference :grader_permissions, :role, foreign_key:true
    remove_foreign_key :grader_permissions, :users
    remove_column :grader_permissions, :user_id, type: :integer
  end
end
