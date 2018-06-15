class AddY2ToAnnotations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :annotations, :y2, :integer
  end

  def self.down
    remove_column :annotations, :y2
  end
end
