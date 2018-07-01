class CreateExamTemplates < ActiveRecord::Migration[4.2]
  def change
    create_table :exam_templates do |t|
      t.references :assignment, index: true, foreign_key: true
      t.string :filename, null: false
      t.integer :num_pages, null: false

      t.timestamps null: false
    end
  end
end
