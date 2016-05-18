class AddColumnsCriterion < ActiveRecord::Migration
  def up
    add_column :rubric_criteria, :ta_visible, :boolean, :default => true, :null => false
    add_column :rubric_criteria, :peer_visible, :boolean, :default => false, :null => false
    add_column :flexible_criteria, :ta_visible, :boolean, :default => true, :null => false
    add_column :flexible_criteria, :peer_visible, :boolean, :default => false, :null => false
  end

  def down
    remove_column :rubric_criteria, :ta_visible
    remove_column :rubric_criteria, :peer_visible
    remove_column :flexible_criteria, :ta_visible
    remove_column :flexible_criteria, :peer_visible
  end
end
