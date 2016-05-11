class CreateFeedbackFiles < ActiveRecord::Migration
  def change
    create_table :feedback_files do |t|
      t.string :filename, null: false
      t.binary :file_content, null: false
      t.string :mime_type, null: false
      t.datetime :created_at
      t.datetime :updated_at
      t.references :submission, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
