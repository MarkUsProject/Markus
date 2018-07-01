class AddY1ToAnnotations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :annotations, :y1, :integer
  end

  def self.down
    remove_column :annotations, :y1
  end
end
