class AddY1ToAnnotations < ActiveRecord::Migration
  def self.up
    add_column :annotations, :y1, :integer
  end

  def self.down
    remove_column :annotations, :y1
  end
end
