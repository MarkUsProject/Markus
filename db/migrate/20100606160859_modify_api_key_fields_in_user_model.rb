class ModifyApiKeyFieldsInUserModel < ActiveRecord::Migration
  def self.up
    remove_column :users, :api_key_md5
  end

  def self.down
    add_column :users, :api_key_md5, :string
  end
end
