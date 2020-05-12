class AddcolumnGraderPermission < ActiveRecord::Migration[6.0]
  def change
    add_column :grader_permission, :create_notes, :boolean
    add_column :grader_permission, :create_delete_annotations, :boolean
    add_column :grader_permission, :manually_collect_and_begin_grading, :boolean
    add_column :grader_permission, :update_grade_entry_students, :boolean
  end
end
