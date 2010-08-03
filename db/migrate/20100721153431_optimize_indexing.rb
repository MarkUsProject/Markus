class OptimizeIndexing < ActiveRecord::Migration
  def self.up
    add_index :marks, :result_id
    remove_index :rubric_criteria, [:assignment_id]
  end

  def self.down
    remove_index :marks, :result_id
    add_index :rubric_criteria, [:assignment_id], :name => "index_rubric_criteria_on_assignment_id"
  end
end
