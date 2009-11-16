class MakeCriterionWeightNotNullAgain < ActiveRecord::Migration
  def self.up
    change_column :rubric_criteria, :weight, :float, {:null => false}
  end

  def self.down
    change_column :rubric_criteria, :weight, :float
  end
end
