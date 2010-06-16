class AddX2ToAnnotations < ActiveRecord::Migration
  def self.up
    add_column :annotations, :x2, :integer
  end

  def self.down
    remove_column :annotations, :x2
  end
end
