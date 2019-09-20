class DropLevels < ActiveRecord::Migration[6.0]
  def change
    drop_table :levels
  end
end
