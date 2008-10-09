require 'migration_helpers'

class ModifySubmissions < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table(:submissions, :force => true) do |t|
      t.column  :user_id,         :int
      t.column  :group_id,        :int
      t.column  :assignment_id,   :int
    end
    
    foreign_key_no_delete :submissions, :user_id, :users
     foreign_key_no_delete :submissions, :group_id, :groups
    foreign_key_no_delete :submissions, :assignment_id, :assignments
  end

  def self.down
    drop_table :submissions
  end
end
