class RemoveTotalMarkFromResults < ActiveRecord::Migration
  def self.up
    remove_column :results, :total_mark
  end

  def self.down
    add_column :results, :total_mark, :float
  end
end
