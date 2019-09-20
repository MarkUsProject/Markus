class CreateLevels < ActiveRecord::Migration[6.0]
  def change
    create_table :levels do |t|
      t.integer :assignment_id, null: false
      t.integer :rubric_criterion_id, null: false
      t.integer :level_num, null: false
      t.string :level_name, null: false
      t.string :level_description
      t.integer :mark, null: false
    end
  end
end
