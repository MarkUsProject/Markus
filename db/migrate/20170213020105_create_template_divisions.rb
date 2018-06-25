class CreateTemplateDivisions < ActiveRecord::Migration[4.2]
  def change
    create_table :template_divisions do |t|
      t.references :exam_template, index: true, foreign_key: true
      t.integer :start, null: false
      t.integer :end, null: false
      t.string :label, unique: true, null: false

      t.timestamps null: false
    end
  end
end
