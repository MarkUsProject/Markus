class ChangeFileNameToPublicKeyInKeyPairs < ActiveRecord::Migration[6.0]
  def change
    rename_column :key_pairs, :file_name, :public_key
  end
end
