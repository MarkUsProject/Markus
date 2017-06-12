class CreateSplitPdfLogs < ActiveRecord::Migration
  def change
    create_table :split_pdf_logs do |t|
      t.string :state, null: false
      t.string :split_filetype, null: false
      t.string :split_filename, null: false
      t.string :user, null: false
      t.string :host, null: false

      t.timestamps null: false
    end
  end
end
