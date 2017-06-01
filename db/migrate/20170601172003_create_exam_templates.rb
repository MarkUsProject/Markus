class CreateExamTemplates < ActiveRecord::Migration
  def change
    create_table :exam_templates do |t|
      t.references :assignment, index: true, foreign_key: true
      t.string :filename
      t.string :name
      t.integer :num_pages

      t.timestamps null: false
    end
  end
end
