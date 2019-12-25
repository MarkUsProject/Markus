class RemoveNumberFromLevels < ActiveRecord::Migration[6.0]
  def change

    remove_column :levels, :number, :integer
  end
end
