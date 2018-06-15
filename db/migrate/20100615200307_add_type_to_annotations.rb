class AddTypeToAnnotations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :annotations, :type, :string
  end

  def self.down
    remove_column :annotations, :type
  end
end
