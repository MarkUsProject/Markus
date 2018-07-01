class AddX2ToAnnotations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :annotations, :x2, :integer
  end

  def self.down
    remove_column :annotations, :x2
  end
end
