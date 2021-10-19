class ChangeGraderPermissionsForeignKey < ActiveRecord::Migration[6.1]
  def change
    add_reference :grader_permissions, :roles, foreign_key:true
    remove_foreign_key :grader_permissions, :users
  end
end
