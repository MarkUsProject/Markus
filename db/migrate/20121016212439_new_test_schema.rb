class NewTestSchema < ActiveRecord::Migration
  def self.up
    create_table :test_scripts do |t|
      t.references :assignment
      t.float :seq_num
      t.string :name, :script_name
      t.text :description
      t.integer :max_marks
      t.boolean :run_on_submission, :run_on_request, :uses_token, :halts_testing,
        :display_description, :display_run_status, :display_marks_earned,
        :display_input, :display_expected_output, :display_actual_output
    end

    create_table :test_runs do |t|
      t.references :assignment, :test_script, :group
      t.string :result
      t.integer :marks_earned
      t.text :input, :actual_output, :expected_output
    end

    drop_table :test_files
    drop_table :test_results
  end

  def self.down
    drop_table :test_scripts
    drop_table :test_runs

    create_table "test_files", :force => true do |t|
      t.string   "filename"
      t.integer  "assignment_id"
      t.string   "filetype"
      t.boolean  "is_private"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "test_files", ["assignment_id", "filename"], :name => "index_test_files_on_assignment_id_and_filename", :unique => true

    create_table "test_results", :force => true do |t|
      t.string   "filename"
      t.text     "file_content"
      t.integer  "submission_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "status"
      t.integer  "user_id"
    end

    add_index "test_results", ["filename"], :name => "index_test_results_on_filename"
    add_index "test_results", ["submission_id"], :name => "index_test_results_on_submission_id"
  end
end
