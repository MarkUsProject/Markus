class AddAllowWebSubmitsFieldToAssignmentsTable < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :allow_web_submits, :boolean, :default => true
  end

  def self.down
    remove_column :assignments, :allow_web_submits
  end
end
