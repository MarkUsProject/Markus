class CreateSplitPages < ActiveRecord::Migration[4.2]
  def change
    create_table :split_pages do |t|
      t.integer :raw_page_number
      t.integer :exam_page_number
      t.string :filename
      t.string :status
      t.references :split_pdf_log, index: true, foreign_key: true
      t.references :group, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
