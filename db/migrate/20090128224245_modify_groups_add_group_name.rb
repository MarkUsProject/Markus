class ModifyGroupsAddGroupName < ActiveRecord::Migration[4.2]
  def self.up
  	add_column :groups, :name, :text
  end

  def self.down
  	remove_column :groups, :name
  end
end
