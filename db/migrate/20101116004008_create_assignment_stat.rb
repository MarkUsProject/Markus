class CreateAssignmentStat < ActiveRecord::Migration[4.2]
  extend MigrationHelpers

  def self.up
    create_table :assignment_stats do |t|
      t.column  :assignment_id,                 :int
      t.column  :grade_distribution_percentage, :text
    end

    foreign_key :assignment_stats, :assignment_id, :assignments
  end

  def self.down
    drop_table :assignment_stats
  end
end
