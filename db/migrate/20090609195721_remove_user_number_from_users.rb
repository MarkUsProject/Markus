class RemoveUserNumberFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :user_number
  end

  def self.down
    add_column :users, :user_number, :string
    add_index :users, :user_number, :unique => true
  end
end
