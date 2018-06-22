class CreateSplitPdfLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :split_pdf_logs do |t|
      t.datetime :uploaded_when
      t.string :error_description
      t.string :filename
      t.references :user, index: true, foreign_key: true
      t.integer :num_groups_in_complete
      t.integer :num_groups_in_incomplete
      t.integer :num_pages_qr_scan_error
      t.integer :original_num_pages
      t.boolean :qr_code_found

      t.timestamps null: false
    end
  end
end
