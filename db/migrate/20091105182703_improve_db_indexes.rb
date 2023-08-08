class ImproveDbIndexes < ActiveRecord::Migration[4.2]
  def self.up
    add_index :groupings, [:assignment_id, :group_id], :unique => true, :name => "groupings_u1"
    remove_index :groupings, :name => "index_groupings_on_assignment_id"
    remove_index :groupings, :name => "index_groupings_on_group_id"

    add_index :memberships, [:grouping_id, :user_id], :unique => true, :name => "memberships_u1"
    remove_index :memberships, :name => "index_memberships_on_grouping_id"
    remove_index :memberships, :name => "index_memberships_on_user_id"

    add_index :results, :submission_id, :unique => true, :name => "results_u1"

    change_column :groups, :group_name, :string, limit: 30
    add_index :groups, :group_name, :name => "groups_n1"
  end

  def self.down
    remove_index :groupings, :name => "groupings_u1"
    add_index :groupings, :assignment_id, :unique => false, :name => "index_groupings_on_assignment_id"
    add_index :groupings, :group_id, :unique => false, :name => "index_groupings_on_group_id"

    remove_index :memberships, :name => "memberships_u1"
    add_index :memberships, :grouping_id, :unique => false, :name => "index_memberships_on_grouping_id"
    add_index :memberships, :user_id, :unique => false, :name => "index_memberships_on_user_id"

    remove_index :results, :name => "results_u1"
    remove_index :groups, :name => "groups_n1"

    change_column :groups, :group_name, :text
  end
end
