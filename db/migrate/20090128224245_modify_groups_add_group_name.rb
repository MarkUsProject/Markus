class ModifyGroupsAddGroupName < ActiveRecord::Migration
  def self.up
  	add_column :groups, :name, :text
  end

  def self.down
  	remove_column :groups, :name
  end
end
