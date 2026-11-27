class AddIndexesToUnindexedForeignKeys < ActiveRecord::Migration[8.1]
  def change
    add_index :annotation_texts, :creator_id
    add_index :annotation_texts, :last_editor_id
    add_index :annotations, :annotation_text_id
    add_index :annotations, :result_id
    add_index :assessment_section_properties, :assessment_id
    add_index :assessment_section_properties, :section_id
    add_index :assignment_properties, :remote_autotest_settings_id
    add_index :criteria_assignment_files_joins, :assignment_file_id
    add_index :criteria_assignment_files_joins, :criterion_id
    add_index :criterion_ta_associations, :assessment_id
    add_index :grade_entry_students, :assessment_id
    add_index :grade_entry_students_tas, :ta_id
    add_index :grades, :grade_entry_student_id
    add_index :groupings, :group_id
    add_index :groupings_tags, :grouping_id
    add_index :key_pairs, :user_id
    add_index :lti_deployments, :lms_course_id
    add_index :marking_weights, :marking_scheme_id
    add_index :memberships, :grouping_id
    add_index :notes, %i[noteable_type noteable_id]
    add_index :template_divisions, :assignment_file_id
    add_index :test_runs, :autotest_test_id
  end
end
