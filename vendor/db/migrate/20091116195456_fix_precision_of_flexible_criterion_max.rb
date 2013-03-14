class FixPrecisionOfFlexibleCriterionMax < ActiveRecord::Migration
  def self.up
    change_column :flexible_criteria, :max, :decimal, {:precision => 10, :scale => 1, :null => false}
  end

  def self.down
    change_column :flexible_criteria, :max, :decimal, {:precision => 10, :scale => 0, :null => false}
  end
end
