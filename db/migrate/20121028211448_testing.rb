class Testing < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :test_files
    drop_table :test_results

    create_table :test_script_results do |t|
      t.references :grouping
      t.references :test_script
      t.integer "marks_earned"
      t.integer "repo_revision"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table :test_support_files do |t|
      t.string :file_name, null: false
      t.references :assignment, null: false
      t.text :description, null: false
    end

    add_index :test_support_files,
              ["assignment_id"],
              :name => "index_test_files_on_assignment_id"

    create_table :test_scripts do |t|
      t.integer "assignment_id", null: false
      t.float   "seq_num", null: false
      t.string  "script_name", null: false
      t.text    "description", null: false
      t.integer "max_marks", null: false
      t.boolean "run_on_submission"
      t.boolean "run_on_request"
      t.boolean "halts_testing"
      t.string "display_description", null: false
      t.string "display_run_status",  null: false
      t.string "display_marks_earned",  null: false
      t.string "display_input",  null: false
      t.string "display_expected_output",  null: false
      t.string "display_actual_output",  null: false
    end

    add_index :test_scripts,
              ["assignment_id", "seq_num"],
              :name => "index_test_scripts_on_assignment_id_and_seq_num"


    create_table :test_results do |t|
      t.references :grouping
      t.references :test_script
      t.references :test_script_result
      t.string "name"
      t.string "completion_status",  null: false
      t.integer "marks_earned",  null: false
      t.integer "repo_revision"
      t.text    "input_description",  null: false
      t.text    "actual_output",  null: false
      t.text    "expected_output",  null: false
    end

    add_index :test_results,
              ["grouping_id", "test_script_id"],
              :name => "grouping_id_and_test_script_id"
  end

  def self.down
    drop_table :test_scripts
    drop_table :test_results
    drop_table :test_support_files
    drop_table :test_script_results

    create_table "test_files", :force => true do |t|
      t.string   "filename"
      t.integer  "assignment_id"
      t.string   "filetype"
      t.boolean  "is_private"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

      add_index "test_files",
                ["assignment_id", "filename"],
                :name => "index_test_files_on_assignment_id_and_filename",
                :unique => true

      create_table "test_results", :force => true do |t|
        t.string   "filename"
        t.text     "file_content"
        t.integer  "submission_id"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.string   "status"
        t.integer  "user_id"
      end

        add_index "test_results",
                  ["filename"],
                  :name => "index_test_results_on_filename"
        add_index "test_results",
                  ["submission_id"],
                  :name => "index_test_results_on_submission_id"
  end
end
