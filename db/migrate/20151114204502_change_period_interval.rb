class ChangePeriodInterval < ActiveRecord::Migration
  def change
    change_column :periods, :interval, :float
  end
end
