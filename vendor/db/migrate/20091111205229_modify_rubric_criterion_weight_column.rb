class ModifyRubricCriterionWeightColumn < ActiveRecord::Migration
  # Table rubric_criteria has attribute weight.
  # Earlier migrations made the weight attribute of type decimal
  # which is translated into MySQL native type Decimal(10,0)
  # i.e. this means basically a decimal number allowing 10 digits
  # prior the decimal point and 0 (!) after the decimal point.
  # We don't want this. I'm going with float now.
  def self.up
    change_table :rubric_criteria do |t|
      t.remove :weight
      t.float :weight
    end
  end

  def self.down
    change_table :rubric_criteria do |t|
      t.remove :weight
      t.decimal :weight
    end
  end
end
