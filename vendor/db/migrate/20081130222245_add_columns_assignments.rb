class AddColumnsAssignments < ActiveRecord::Migration

  def self.up
    # boolean flag to check if students are allowed to form groups
    add_column :assignments, :student_form_groups, :boolean

    # time limit that students can invite other members
    add_column :assignments, :student_invite_until, :datetime

  end

  def self.down
    remove_column :assignments, :student_form_groups
    remove_column :assignments, :student_invite_until
  end
end
