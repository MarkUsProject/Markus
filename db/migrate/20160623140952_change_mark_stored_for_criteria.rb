class ChangeMarkStoredForCriteria < ActiveRecord::Migration
  def change
    rename_column :flexible_criteria, :max, :max_mark
    rename_column :rubric_criteria, :weight, :max_mark
    reversible do |dir|
      change_table :rubric_criteria do |t|
        dir.up   { t.change :max_mark, :decimal, precision:10, scale:1, null:false }
        dir.down { t.change :max_mark, :float, null: false }
      end
    end
  end
end
