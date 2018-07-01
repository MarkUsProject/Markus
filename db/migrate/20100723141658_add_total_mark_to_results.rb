class AddTotalMarkToResults < ActiveRecord::Migration[4.2]
  def self.up
    add_column :results, :total_mark, :float, :default => 0
  end

  def self.down
    remove_column :results, :total_mark
  end
end
