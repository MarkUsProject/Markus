class ModifyMarksTable < ActiveRecord::Migration
  def self.up
    change_column :marks, :mark, :float
  end

  def self.down
    change_column :marks, :mark, :int
  end
end
