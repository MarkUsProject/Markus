class RenameValidGroupingColumnToAdminApproved < ActiveRecord::Migration
  def self.up
    rename_column :groupings, :valid_grouping, :admin_approved
  end

  def self.down
    rename_column :groupings, :admin_approved, :valid_grouping
  end
end
