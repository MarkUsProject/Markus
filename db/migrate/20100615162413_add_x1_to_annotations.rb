class AddX1ToAnnotations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :annotations, :x1, :integer
  end

  def self.down
    remove_column :annotations, :x1
  end
end
