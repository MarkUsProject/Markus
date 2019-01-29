class ChangeTestScriptsToTestGroups < ActiveRecord::Migration[5.2]
  def change
    rename_table :test_scripts, :test_groups
    change_table :test_groups do |t|
      t.remove :assignment_id, :criterion_id, :criterion_type, :seq_num, :description, :halts_testing,
               :display_description, :display_run_status, :display_marks_earned, :display_input,
               :display_expected_output, :timeout
      t.references :assignment, index: true, foreign_key: true, null: false
      t.references :criterion, polymorphic: true, index: true
      t.rename :file_name, :name
      t.change :name, :text
      t.rename :display_actual_output, :display_output
      t.change :display_output, :integer, using: 'display_output::integer', null: false, default: 0
      t.change :run_by_instructors, :boolean, null: false, default: true
      t.change :run_by_students, :boolean, null: false, default: false
      t.index [:assignment_id, :name], unique: true
      t.timestamps
    end

    rename_table :test_script_results, :test_group_results
    change_table :test_group_results do |t|
      t.rename :test_script_id, :test_group_id
      t.change :created_at, :timestamp, null: false
      t.change :updated_at, :timestamp, null: false
    end

    change_table :test_results do |t|
      t.remove :test_script_result_id, :input, :expected_output
      t.references :test_group_result, index: true, foreign_key: true, null: false
      t.change :name, :text, null: false
      t.change :completion_status, :text
      t.rename :actual_output, :output
      t.rename :completion_status, :status
    end

    add_column :test_runs, :problems, :text

    drop_table :test_support_files
  end
end
