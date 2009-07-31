class RemoveStudentInviteUntilFromAssignmentTable < ActiveRecord::Migration
  def self.up
    remove_column :assignments, :student_invite_until
  end

  def self.down
    add_column :assignments, :student_invite_until, :datetime
  end
end
