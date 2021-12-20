class UniqueUserPerCourse < ActiveRecord::Migration[6.1]
  def change
    add_index :roles, [:user_id, :course_id], unique: true
  end
end
