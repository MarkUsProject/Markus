require 'migration_helpers'

class CreateSubmissionRules < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    # single table inheritance of submission rules
    create_table :submission_rules do |t|

      t.column  :assignment_id,       :integer, :null => false
      # number of hours a student can submit after deadline
      t.column  :allow_submit_until,  :integer, :default => 0


      t.column  :type,                :string, :default => "NullSubmissionRule"

      # Grace Day rules
      t.column  :grace_day_limit, :integer

      # Penalty formula rules
      t.column  :penalty_limit,         :integer
      t.column  :penalty_increment,     :integer
      t.column  :penalty_interval,      :integer
      t.column  :penalty_interval_unit, :string

      t.timestamps
    end

    foreign_key :submission_rules, :assignment_id, :assignments
  end

  def self.down
    drop_table  :submission_rules
  end

end
