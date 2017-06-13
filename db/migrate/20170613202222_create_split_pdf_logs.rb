class CreateSplitPdfLogs < ActiveRecord::Migration
  def change
    create_table :split_pdf_logs do |t|
      t.string :split_pdf_console_log, null: false
      t.string :error_description, null: false
      t.string :uploaded_filetype, null: false
      t.string :uploaded_filename, null: false
      t.string :user, null: false
      t.string :host, null: false
      t.string :list_of_new_files_in_raw_dir, null: false
      t.string :list_of_new_files_in_complete_dir, null: false
      t.string :list_of_new_files_in_incomplete_dir, null: false
      t.string :list_of_new_files_in_error_dir, null: false
      t.integer :original_num_pages, null: false
      t.integer :split_into_how_many_pages, null: false
      t.boolean :qr_code_found, null: false
      t.boolean :missing_pages, null: false

      t.timestamps null: false
    end
  end
end
