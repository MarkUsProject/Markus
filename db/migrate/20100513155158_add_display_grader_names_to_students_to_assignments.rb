class AddDisplayGraderNamesToStudentsToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :display_grader_names_to_students, :boolean
  end

  def self.down
    remove_column :assignments, :display_grader_names_to_students
  end
end
