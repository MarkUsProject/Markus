class CreateSplitPages < ActiveRecord::Migration
  def change
    create_table :split_pages do |t|
      t.integer :page_number
      t.string :filename
      t.string :error_description
      t.references :exam_template, index: true, foreign_key: true
      t.references :group, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
