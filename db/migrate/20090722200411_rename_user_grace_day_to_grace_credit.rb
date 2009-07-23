class RenameUserGraceDayToGraceCredit < ActiveRecord::Migration
  def self.up
    rename_column :users, :grace_days, :grace_credits
  end

  def self.down
    rename_column :users, :grace_credits, :grace_days
  end
end
