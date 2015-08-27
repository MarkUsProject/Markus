class MarksPolymorphicAssociation < ActiveRecord::Migration
  def self.up
    rename_column :marks, :rubric_criterion_id, :markable_id
    add_column :marks, :markable_type, :string
    add_index :marks, [:markable_id, :result_id, :markable_type], :unique => true, :name => "marks_u1"
    remove_index :marks, :name => "index_marks_on_result_id"
  end

  def self.down
    rename_column :marks, :markable_id, :rubric_criterion_id
    remove_column :marks, :markable_type
    remove_index :marks, :name => "marks_u1"
    add_index :marks, [:result_id]

  end
end
