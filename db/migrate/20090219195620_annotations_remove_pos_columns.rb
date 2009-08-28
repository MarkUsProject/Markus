class AnnotationsRemovePosColumns < ActiveRecord::Migration
  def self.up
    remove_column :annotations, :pos_start
    remove_column :annotations, :pos_end
  end

  def self.down
    add_column :annotations, :pos_start, :integer
    add_column :annotations, :pos_end, :integer
  end
end
