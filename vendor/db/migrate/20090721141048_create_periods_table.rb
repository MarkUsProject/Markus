class CreatePeriodsTable < ActiveRecord::Migration
  def self.up
    create_table :periods do |t|
      t.column :start_time, :datetime
      t.column :end_time,  :datetime
      t.column :submission_rule_id,  :int
      t.column :deduction, :float
      t.timestamps
    end
    add_index :periods, :submission_rule_id
  end

  def self.down
    remove_index :periods, :submission_rule_id
    drop_table :periods
  end
end
