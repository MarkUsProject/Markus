class CreateGracePeriodDeductions < ActiveRecord::Migration
  def self.up
    create_table :grace_period_deductions do |t|
      t.column :membership_id, :int
      t.column :deduction,  :int
      t.timestamps
    end
    add_index :grace_period_deductions, :membership_id
  end

  def self.down
    remove_index :grace_period_deductions, :membership_id
    drop_table :grace_period_deductions
  end
end
