class AddForeignCriterionIdToMarks < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    rename_column(:marks, :criterion_id, :rubric_criteria_id)
    foreign_key(:marks,:rubric_criteria_id, :rubric_criterias)
  end

  def self.down
    rename_column(:marks, :rubric_criteria_id, :criterion_id)
    delete_foreign_key(:marks, :rubric_criteria_id)
  end
end
