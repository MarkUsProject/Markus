class CreateSplitPdfLogs < ActiveRecord::Migration
  def change
    create_table :split_pdf_logs do |t|
      t.string :split_pdf_console_log
      t.string :error_description
      t.string :uploaded_filetype
      t.string :uploaded_filename
      t.string :user
      t.string :host
      t.string :list_of_new_files_in_raw_dir
      t.string :list_of_new_files_in_complete_dir
      t.string :list_of_new_files_in_incomplete_dir
      t.string :list_of_new_files_in_error_dir
      t.integer :original_num_pages
      t.integer :split_into_how_many_pages
      t.boolean :qr_code_found
      t.boolean :missing_pages

      t.timestamps null: false
    end
  end
end
