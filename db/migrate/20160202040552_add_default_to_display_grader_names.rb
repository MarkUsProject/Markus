class AddDefaultToDisplayGraderNames < ActiveRecord::Migration
  def up
    change_column_default :assignments, :display_grader_names_to_students,
                          :false
  end

  def down
    change_column_default :assignments, :display_grader_names_to_students, :nil
  end
end
