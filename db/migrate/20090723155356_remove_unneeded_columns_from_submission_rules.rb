class RemoveUnneededColumnsFromSubmissionRules < ActiveRecord::Migration
  def self.up
    remove_column :submission_rules, :allow_submit_until
    remove_column :submission_rules, :grace_day_limit
    remove_column :submission_rules, :penalty_limit
    remove_column :submission_rules, :penalty_increment
    remove_column :submission_rules, :penalty_interval
    remove_column :submission_rules, :penalty_interval_unit
  end

  def self.down
    add_column :submission_rules, :allow_submit_until, :integer, :default => 0
    add_column :submission_rules, :grace_day_limit, :integer
    add_column :submission_rules, :penalty_limit, :integer
    add_column :submission_rules, :penalty_increment, :integer
    add_column :submission_rules, :penalty_interval, :integer
    add_column :submission_rules, :penalty_interval_unit, :string      
  end
end
