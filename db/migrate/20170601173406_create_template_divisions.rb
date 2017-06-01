class CreateTemplateDivisions < ActiveRecord::Migration
  def change
    create_table :template_divisions do |t|
      t.references :exam_template, index: true, foreign_key: true
      t.integer :start
      t.integer :end
      t.string :label

      t.timestamps null: false
    end
  end
end
