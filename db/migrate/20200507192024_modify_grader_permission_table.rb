class ModifyGraderPermissionTable < ActiveRecord::Migration[6.0]
  def change
    add_column :grader_permission, :user_id, :int, :unique => true
    add_column :grader_permission, :delete_grace_period_deduction, :boolean
    remove_column :grader_permission, :description
    remove_column :grader_permission, :is_enabled

    add_foreign_key :grader_permission, :users
  end
end
