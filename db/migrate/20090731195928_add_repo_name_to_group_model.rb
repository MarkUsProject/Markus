class AddRepoNameToGroupModel < ActiveRecord::Migration[4.2]
  def self.up
    add_column :groups, :repo_name, :string
  end

  def self.down
    remove_column :groups, :repo_name, :string
  end
end
