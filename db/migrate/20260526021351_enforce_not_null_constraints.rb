class EnforceNotNullConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :first_name, false
    change_column_null :users, :last_name, false
    change_column_null :users, :created_at, false
    change_column_null :users, :updated_at, false

    change_column_null :annotations, :annotation_text_id, false
    change_column_null :annotations, :submission_file_id, false
    change_column_null :annotations, :annotation_number, false
    change_column_null :annotations, :result_id, false

    change_column_null :annotation_categories, :annotation_category_name, false
    change_column_null :annotation_categories, :created_at, false
    change_column_null :annotation_categories, :updated_at, false

    change_column_null :annotation_texts, :created_at, false
    change_column_null :annotation_texts, :updated_at, false

    change_column_null :assessment_section_properties, :section_id, false
    change_column_null :assessment_section_properties, :assessment_id, false

    change_column_null :assignment_files, :created_at, false
    change_column_null :assignment_files, :updated_at, false
    change_column_null :assignment_files, :assessment_id, false

    change_column_null :assignment_properties, :assessment_id, false

    change_column_null :criteria_assignment_files_joins, :created_at, false
    change_column_null :criteria_assignment_files_joins, :updated_at, false

    change_column_null :criterion_ta_associations, :ta_id, false
    change_column_null :criterion_ta_associations, :criterion_id, false
    change_column_null :criterion_ta_associations, :created_at, false
    change_column_null :criterion_ta_associations, :updated_at, false
    change_column_null :criterion_ta_associations, :assessment_id, false

    change_column_null :exam_templates, :assessment_id, false

    change_column_null :extra_marks, :result_id, false
    change_column_null :extra_marks, :created_at, false
    change_column_null :extra_marks, :updated_at, false
    change_column_null :extra_marks, :unit, false

    change_column_null :grace_period_deductions, :created_at, false
    change_column_null :grace_period_deductions, :updated_at, false

    change_column_null :submission_rules, :created_at, false
    change_column_null :submission_rules, :updated_at, false

    change_column_null :grades, :grade_entry_item_id, false
    change_column_null :grades, :grade_entry_student_id, false
    change_column_null :grades, :created_at, false
    change_column_null :grades, :updated_at, false

    change_column_null :grade_entry_items, :created_at, false
    change_column_null :grade_entry_items, :updated_at, false
    change_column_null :grade_entry_items, :out_of, false
    change_column_null :grade_entry_items, :position, false
    change_column_null :grade_entry_items, :assessment_id, false

    change_column_null :grade_entry_students, :created_at, false
    change_column_null :grade_entry_students, :updated_at, false
    change_column_null :grade_entry_students, :assessment_id, false

    change_column_null :grade_entry_students_tas, :grade_entry_student_id, false
    change_column_null :grade_entry_students_tas, :ta_id, false

    change_column_null :groupings, :created_at, false
    change_column_null :groupings, :updated_at, false

    change_column_null :key_pairs, :user_id, false
    change_column_null :key_pairs, :public_key, false
    change_column_null :key_pairs, :created_at, false
    change_column_null :key_pairs, :updated_at, false

    change_column_null :marks, :result_id, false
    change_column_null :marks, :criterion_id, false
    change_column_null :marks, :created_at, false
    change_column_null :marks, :updated_at, false

    change_column_null :marking_schemes, :created_at, false
    change_column_null :marking_schemes, :updated_at, false

    change_column_null :marking_weights, :marking_scheme_id, false
    change_column_null :marking_weights, :created_at, false
    change_column_null :marking_weights, :updated_at, false

    change_column_null :memberships, :created_at, false
    change_column_null :memberships, :updated_at, false

    change_column_null :notes, :created_at, false
    change_column_null :notes, :updated_at, false

    change_column_null :periods, :submission_rule_id, false
    change_column_null :periods, :created_at, false
    change_column_null :periods, :updated_at, false
    change_column_null :periods, :submission_rule_type, false

    change_column_null :results, :submission_id, false
    change_column_null :results, :marking_state, false
    change_column_null :results, :created_at, false
    change_column_null :results, :updated_at, false

    change_column_null :sections, :name, false
    change_column_null :sections, :created_at, false
    change_column_null :sections, :updated_at, false

    change_column_null :split_pages, :split_pdf_log_id, false

    change_column_null :split_pdf_logs, :filename, false
    change_column_null :split_pdf_logs, :num_groups_in_complete, false
    change_column_null :split_pdf_logs, :num_groups_in_incomplete, false
    change_column_null :split_pdf_logs, :num_pages_qr_scan_error, false
    change_column_null :split_pdf_logs, :original_num_pages, false
    change_column_null :split_pdf_logs, :exam_template_id, false

    change_column_null :submissions, :grouping_id, false
    change_column_null :submissions, :created_at, false

    change_column_null :submission_files, :submission_id, false
    change_column_null :submission_files, :filename, false

    change_column_null :template_divisions, :exam_template_id, false

    change_column_null :test_results, :created_at, false
    change_column_null :test_results, :updated_at, false
  end
end
