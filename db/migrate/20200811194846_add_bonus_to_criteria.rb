class AddBonusToCriteria < ActiveRecord::Migration[6.0]
  def change
    add_column :criteria, :bonus, :boolean, default: false, null: false
  end
end
