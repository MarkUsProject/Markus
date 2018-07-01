class RemoveStatusPropertyFromGroups < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :groups, :status
  end

  def self.down
    add_column :groups, :status, :string
  end
end
