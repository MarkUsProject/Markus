class SetDefaultGraceCreditToZero < ActiveRecord::Migration
  def self.up
    change_column :users, :grace_credits, :int, :default => 0, :null => false
  end

  def self.down
    change_column :users, :grace_credits, :int
  end
end
