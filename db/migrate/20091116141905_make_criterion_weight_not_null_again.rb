class MakeCriterionWeightNotNullAgain < ActiveRecord::Migration[4.2]
  def self.up
    change_column :rubric_criteria, :weight, :float, null: false
  end

  def self.down
    change_column :rubric_criteria, :weight, :float
  end
end
