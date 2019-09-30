class CreateLevels < ActiveRecord::Migration[6.0]
  def change
    create_table :levels do |t|
      t.belongs_to :rubric_criterion, foreign_key: true, null: false
      t.string :name, null: false
      t.integer :number, null: false
      t.text :description, null: false
      t.float :mark, null: false

      t.timestamps
    end
  end
end
