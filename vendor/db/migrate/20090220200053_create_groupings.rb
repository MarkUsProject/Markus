require 'migration_helpers'

class CreateGroupings < ActiveRecord::Migration

  extend MigrationHelpers

  def self.up

    create_table :groupings do |t|
      t.column    :group_id,   :int, :null => false
      t.column    :assignment_id,   :int, :null => false
      t.timestamps
    end

    foreign_key_no_delete :groupings, :group_id,  :groups
    foreign_key_no_delete :groupings, :assignment_id,  :assignments

    delete_foreign_key :memberships, :groups
    remove_column :memberships, :group_id

    add_column :memberships, :grouping_id, :int, :null => false
    foreign_key_no_delete :memberships, :grouping_id,  :groupings

    remove_column :submissions, :user_id
    remove_column :submissions, :group_id
    remove_column :submissions, :assignment_id
    add_column :submissions, :grouping_id, :int

  end

  def self.down
    add_column :memberships, :group_id, :int
    foreign_key_no_delete :memberships, :group_id, :groups

    delete_foreign_key :memberships, :groupings
    remove_column :memberships, :grouping_id

    delete_foreign_key :groupings, :groups
    delete_foreign_key :groupings, :assignments
    drop_table :groupings

    add_column :submissions, :user_id, :int
    add_column :submissions, :group_id, :int
    add_column :submissions, :assignment_id, :int
    remove_column :submissions, :grouping_id
  end
end
