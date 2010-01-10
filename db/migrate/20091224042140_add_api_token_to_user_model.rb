class AddApiTokenToUserModel < ActiveRecord::Migration
  def self.up
    add_column :users, :api_key, :string
    add_column :users, :api_key_md5, :string
  end

  def self.down
    remove_column :users, :api_key
    remove_column :users, :api_key_md5
  end
end
