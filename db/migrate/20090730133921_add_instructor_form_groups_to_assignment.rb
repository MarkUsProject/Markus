class AddInstructorFormGroupsToAssignment < ActiveRecord::Migration
  def self.up
    add_column :assignments, :instructor_form_groups, :boolean
  end

  def self.down
    remove_column :assignments, :instructor_form_groups
  end
end
