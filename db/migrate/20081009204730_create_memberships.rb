require 'migration_helpers'

class CreateMemberships < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table :memberships do |t|
      t.column  :user_id,         :int
      t.column  :group_id,        :int
      t.column  :status,          :string
      t.timestamps
    end

    add_index :memberships, [:user_id, :group_id], :unique => true
    foreign_key_no_delete :memberships, :user_id,  :users
    foreign_key_no_delete :memberships, :group_id,  :groups
  end

  def self.down
    drop_table :memberships
  end
  
end
