class AddX1ToAnnotations < ActiveRecord::Migration
  def self.up
    add_column :annotations, :x1, :integer
  end

  def self.down
    remove_column :annotations, :x1
  end
end
