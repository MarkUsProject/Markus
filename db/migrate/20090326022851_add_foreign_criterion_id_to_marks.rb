class AddForeignCriterionIdToMarks < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    rename_column(:marks, :criterion_id, :rubric_criterion_id)
    foreign_key(:marks,:rubric_criterion_id, :rubric_criteria)
  end

  def self.down
    rename_column(:marks, :rubric_criterion_id, :criterion_id)
    delete_foreign_key(:marks, :rubric_criterion_id)
  end
end
