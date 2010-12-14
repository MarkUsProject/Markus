require 'migration_helpers'

class CreateAssignmentStat < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :assignment_stats do |t|
      t.column  :assignment_id,                 :int
      t.column  :grade_distribution_percentage, :text,
                    :default => "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n"
    end

    foreign_key :assignment_stats, :assignment_id, :assignments
  end

  def self.down
    drop_table :assignment_stats
  end
end
