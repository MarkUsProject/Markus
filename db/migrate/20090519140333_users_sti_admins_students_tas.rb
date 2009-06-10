# This migration gives us Single Table Inheritence on User model
# for Admins, TAs, and Students
class UsersStiAdminsStudentsTas < ActiveRecord::Migration
  def self.up
    rename_column :users, :role, :type
  end

  def self.down
    rename_column :users, :type, :role
  end
end
