class RemoveUserFromTags < ActiveRecord::Migration[4.2]
  def change
    remove_column :tags, :user
    remove_index :tags, :user if index_exists?(:tags, :user)
  end
end
