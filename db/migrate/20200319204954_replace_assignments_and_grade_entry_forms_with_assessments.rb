class ReplaceAssignmentsAndGradeEntryFormsWithAssessments < ActiveRecord::Migration[6.0]
  def change

    # Ensure rollback contains the correct names & indexes
    reversible do |change|
      change.down do
        add_index :assignment_files, [:assignment_id, :filename], unique: true
        add_index :checkbox_criteria, [:assignment_id, :name], unique: true
        add_index :groupings, [:assignment_id, :group_id], name: "groupings_u1", unique: true
        add_index :rubric_criteria, [:assignment_id, :name], name: "rubric_criteria_index_1", unique: true
        add_index :flexible_criteria, [:assignment_id, :name], unique: true
        add_index :grade_entry_items, [:grade_entry_form_id, :name], unique: true
        add_index :grade_entry_students, [:user_id, :grade_entry_form_id], unique: true

        add_index :assignments, [:short_identifier], unique: true
        add_index :grade_entry_forms, [:short_identifier], unique: true

        add_foreign_key :annotation_categories, :assignments, name: "fk_annotation_categories_assignments", on_delete: :cascade
        add_foreign_key :assignment_files, :assignments, name: "fk_assignment_files_assignments", on_delete: :cascade
        add_foreign_key :assignment_stats, :assignments, name: "fk_assignment_stats_assignments", on_delete: :cascade
        add_foreign_key :checkbox_criteria, :assignments
        add_foreign_key :exam_templates, :assignments
        add_foreign_key :groupings, :assignments, name: "fk_groupings_assignments"
        add_foreign_key :rubric_criteria, :assignments, name: "fk_rubric_criteria_assignments", on_delete: :cascade
        add_foreign_key :test_groups, :assignments
      end
    end

    create_table :assessments, id: :serial, force: :cascade do |t|
      t.string :short_identifier, null: false
      t.string :type, null: false
      t.string :description, null: false
      t.text :message, default: "", null: false
      t.datetime :due_date
      t.boolean :is_hidden, default: true, null: false

      t.boolean :show_total, default: false, null: false
      t.integer :rubric_criteria_count
      t.integer :flexible_criteria_count
      t.integer :checkbox_criteria_count
      t.integer :groupings_count
      t.integer :outstanding_remark_request_count
      t.integer :notes_count, default: 0
      t.integer :parent_assessment_id

      t.timestamps
    end
    add_index :assessments, [:type, :short_identifier]

    create_table :assignment_properties, id: :serial, force: :cascade do |t|
      t.belongs_to :assessment, index: { unique: true }, foreign_key: {on_delete: :cascade}

      t.integer :group_min, default: 1, null: false
      t.integer :group_max, default: 1, null: false
      t.boolean :student_form_groups, default: false, null: false
      t.boolean :group_name_autogenerated, default: true, null: false
      t.boolean :group_name_displayed, default: false, null: false
      t.string :repository_folder, null: false
      t.boolean :invalid_override, default: false, null: false
      t.float :results_average
      t.boolean :allow_web_submits, default: true, null: false
      t.boolean :section_groups_only, default: false, null: false
      t.boolean :section_due_dates_type, default: false, null: false
      t.boolean :display_grader_names_to_students, default: false, null: false
      t.boolean :enable_test, default: false, null: false
      t.boolean :assign_graders_to_criteria, default: false, null: false
      t.integer :tokens_per_period, default: 0, null: false
      t.boolean :allow_remarks, default: false, null: false
      t.datetime :remark_due_date
      t.text :remark_message
      t.float :results_median
      t.integer :results_fails
      t.integer :results_zeros
      t.boolean :unlimited_tokens, default: false, null: false
      t.boolean :only_required_files, default: false, null: false
      t.boolean :vcs_submit, default: false, null: false
      t.datetime :token_start_date
      t.float :token_period
      t.boolean :has_peer_review, default: false, null: false
      t.boolean :enable_student_tests, default: false, null: false
      t.boolean :non_regenerating_tokens, default: false, null: false
      t.boolean :scanned_exam, default: false, null: false
      t.boolean :display_median_to_students, default: false, null: false
      t.boolean :anonymize_groups, default: false, null: false
      t.boolean :hide_unassigned_criteria, default: false, null: false

      t.timestamps
    end

    remove_reference :assignment_files, :assignment, index: true
    remove_reference :assignment_stats, :assignment, index: false
    remove_reference :checkbox_criteria, :assignment, index: false, null: false
    remove_reference :exam_templates, :assignment, index: true
    remove_reference :groupings, :assignment, index: false, null: false
    remove_reference :rubric_criteria, :assignment, index: false, null: false
    remove_reference :test_groups, :assignment, index: true, null: false
    remove_reference :annotation_categories, :assignment, index: true, null: false
    remove_reference :criterion_ta_associations, :assignment, index: false
    remove_reference :flexible_criteria, :assignment, index: true, null: false
    remove_reference :section_due_dates, :assignment, index: false
    remove_reference :submission_rules, :assignment, index: true, null: false
    remove_reference :grade_entry_items, :grade_entry_form, index: false
    remove_reference :grade_entry_students, :grade_entry_form, index: false

    add_reference :assignment_files, :assessment, index: true
    add_reference :assignment_stats, :assessment, index: false
    add_reference :checkbox_criteria, :assessment, index: false, null: false
    add_reference :exam_templates, :assessment, index: true
    add_reference :groupings, :assessment, index: false, null: false
    add_reference :rubric_criteria, :assessment, index: false, null: false
    add_reference :test_groups, :assessment, index: true, null: false
    add_reference :annotation_categories, :assessment, index: true, null: false
    add_reference :criterion_ta_associations, :assessment, index: false
    add_reference :flexible_criteria, :assessment, index: true, null: false
    add_reference :section_due_dates, :assessment, index: false
    add_reference :submission_rules, :assessment, index: true, null: false
    add_reference :grade_entry_items, :assessment, index: false
    add_reference :grade_entry_students, :assessment, index: false

    add_foreign_key :annotation_categories, :assessments, name: "fk_annotation_categories_assignments", on_delete: :cascade
    add_foreign_key :assignment_files, :assessments, name: "fk_assignment_files_assignments", on_delete: :cascade
    add_foreign_key :assignment_stats, :assessments, name: "fk_assignment_stats_assignments", on_delete: :cascade
    add_foreign_key :checkbox_criteria, :assessments
    add_foreign_key :exam_templates, :assessments
    add_foreign_key :groupings, :assessments, name: "fk_groupings_assignments"
    add_foreign_key :rubric_criteria, :assessments, name: "fk_rubric_criteria_assignments", on_delete: :cascade
    add_foreign_key :test_groups, :assessments

    add_index :assignment_files, [:assessment_id, :filename], unique: true
    add_index :checkbox_criteria, [:assessment_id, :name], unique: true
    add_index :groupings, [:assessment_id, :group_id], name: "groupings_u1", unique: true
    add_index :rubric_criteria, [:assessment_id, :name], name: "rubric_criteria_index_1", unique: true
    add_index :flexible_criteria, [:assessment_id, :name], unique: true
    add_index :grade_entry_items, [:assessment_id, :name], unique: true
    add_index :grade_entry_students, [:user_id, :assessment_id], unique: true

    drop_table :assignments, id: :serial do |t|
      t.string :short_identifier, null: false
      t.string :description
      t.text :message
      t.datetime :due_date
      t.integer :group_min, default: 1, null: false
      t.integer :group_max, default: 1, null: false
      t.boolean :student_form_groups, default: false, null: false
      t.boolean :group_name_autogenerated, default: true, null: false
      t.boolean :group_name_displayed, default: false, null: false
      t.string :repository_folder, null: false
      t.boolean :invalid_override, default: false, null: false
      t.float :results_average
      t.boolean :allow_web_submits, default: true, null: false
      t.boolean :section_groups_only, default: false, null: false
      t.boolean :section_due_dates_type, default: false, null: false
      t.boolean :display_grader_names_to_students, default: false, null: false
      t.boolean :enable_test, default: false, null: false
      t.integer :notes_count, default: 0
      t.boolean :assign_graders_to_criteria, default: false, null: false
      t.integer :rubric_criteria_count
      t.integer :flexible_criteria_count
      t.integer :groupings_count
      t.integer :tokens_per_period, default: 0, null: false
      t.boolean :allow_remarks, default: false, null: false
      t.datetime :remark_due_date
      t.text :remark_message
      t.float :results_median
      t.integer :results_fails
      t.integer :results_zeros
      t.integer :outstanding_remark_request_count
      t.boolean :unlimited_tokens, default: false, null: false
      t.boolean :is_hidden, default: false, null: false
      t.boolean :only_required_files, default: false, null: false
      t.boolean :vcs_submit, default: false, null: false
      t.datetime :token_start_date
      t.float :token_period
      t.integer :parent_assignment_id
      t.boolean :has_peer_review, default: false, null: false
      t.integer :checkbox_criteria_count
      t.boolean :enable_student_tests, default: false, null: false
      t.boolean :non_regenerating_tokens, default: false, null: false
      t.boolean :scanned_exam, default: false, null: false
      t.boolean :display_median_to_students, default: false, null: false
      t.boolean :anonymize_groups, default: false, null: false
      t.boolean :hide_unassigned_criteria, default: false, null: false

      t.timestamps
    end

    drop_table :grade_entry_forms, id: :serial do |t|
      t.string :short_identifier, null: false
      t.string :description
      t.text :message
      t.date :date
      t.boolean :is_hidden
      t.boolean :show_total

      t.timestamps
    end

  end
end
