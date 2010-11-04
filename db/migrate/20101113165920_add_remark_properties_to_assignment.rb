class AddRemarkPropertiesToAssignment < ActiveRecord::Migration
  def self.up
    add_column :assignments, :allow_remarks, :boolean, :default => true, :null => false
    add_column :assignments, :remark_due_date, :datetime
    add_column :assignments, :remark_message, :text
  end

  def self.down
    remove_column :assignments, :allow_remarks
    remove_column :assignments, :remark_due_date
    remove_column :assignments, :remark_message
  end
end
