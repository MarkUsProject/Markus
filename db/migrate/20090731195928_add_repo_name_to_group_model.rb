class AddRepoNameToGroupModel < ActiveRecord::Migration
  def self.up
    add_column :groups, :repo_name, :string
  end

  def self.down
    remove_column :groups, :repo_name, :string
  end
end
