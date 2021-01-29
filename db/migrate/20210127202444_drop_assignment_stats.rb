class DropAssignmentStats < ActiveRecord::Migration[6.0]
  def up
    drop_table :assignment_stats
  end

  def down
    create_table :assignment_stats do |t|
      t.column  :assignment_id,                 :int
      t.column  :grade_distribution_percentage, :text
    end

    foreign_key :assignment_stats, :assignment_id, :assignments
  end
end
