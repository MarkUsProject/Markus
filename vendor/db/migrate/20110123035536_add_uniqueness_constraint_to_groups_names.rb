class AddUniquenessConstraintToGroupsNames < ActiveRecord::Migration
  def self.up
      remove_index :groups, :name => "groups_n1"
      add_index :groups, :group_name, :name => "groups_name_unique", :unique => true
  end

  def self.down
      add_index :groups, :group_name, :name => "groups_n1"
      remove_index :groups, :name => "groups_name_unique"
  end
end
