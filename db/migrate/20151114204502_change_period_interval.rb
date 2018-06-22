class ChangePeriodInterval < ActiveRecord::Migration[4.2]
  def change
    change_column :periods, :interval, :float
  end
end
