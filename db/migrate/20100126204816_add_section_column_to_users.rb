class AddSectionColumnToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :section_id, :integer
  end

  def self.down
    remove_column :users, :section_id
  end
end
