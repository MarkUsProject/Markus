class AddInstructorFormGroupsToAssignment < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :instructor_form_groups, :boolean
  end

  def self.down
    remove_column :assignments, :instructor_form_groups
  end
end
