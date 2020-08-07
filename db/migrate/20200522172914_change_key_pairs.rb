class ChangeKeyPairs < ActiveRecord::Migration[6.0]
  def change
    rename_column :key_pairs, :file_name, :public_key
    remove_column :key_pairs, :user_name, :string
    add_foreign_key :key_pairs, :users
  end
end
