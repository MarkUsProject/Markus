class AddSectionGroupColumnToAssignmentsTable < ActiveRecord::Migration
  def self.up
    add_column :assignments, :section_groups_only, :boolean
  end

  def self.down
    remove_column :assignments, :section_groups_only
  end
end
