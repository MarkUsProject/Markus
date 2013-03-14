class AddTokenTable < ActiveRecord::Migration
  def self.up
    create_table :tokens do |t|
      t.column :grouping_id, :int
      t.column :tokens, :int
    end
    add_column :assignments, :tokens_per_day, :int
  end

  def self.down
    drop_table :tokens if table_exists?(:tokens)
    remove_column :assignments, :tokens_per_day
  end
end
