class CreateLevels < ActiveRecord::Migration[6.0]
  def change
    create_table :levels do |t|
      t.belongs_to :rubric_criterion, foreign_key: true
      t.string :name, null: false
      t.integer :number, null: false
      t.string :description
      t.float :mark, null: false
      t.timestamps
    end
  end
end
