class AddMissingForeignKeys < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :annotations, :results
    add_foreign_key :annotation_texts, :roles, column: :creator_id
    add_foreign_key :annotation_texts, :roles, column: :last_editor_id
    add_foreign_key :assessment_section_properties, :sections
    add_foreign_key :assessment_section_properties, :assessments
    add_foreign_key :assessments, :assessments, column: :parent_assessment_id
    add_foreign_key :criteria_assignment_files_joins, :criteria
    add_foreign_key :criterion_ta_associations, :roles, column: :ta_id
    add_foreign_key :criterion_ta_associations, :criteria
    add_foreign_key :criterion_ta_associations, :assessments
    add_foreign_key :grace_period_deductions, :memberships
    add_foreign_key :grades, :grade_entry_items
    add_foreign_key :grades, :grade_entry_students
    add_foreign_key :grade_entry_items, :assessments
    add_foreign_key :grade_entry_students, :assessments
    add_foreign_key :grade_entry_students_tas, :grade_entry_students
    add_foreign_key :grade_entry_students_tas, :roles, column: :ta_id
    add_foreign_key :lti_deployments, :courses
    add_foreign_key :lti_deployments, :lti_clients
    add_foreign_key :lti_users, :lti_clients
    add_foreign_key :lti_users, :users
    add_foreign_key :marking_weights, :marking_schemes
    add_foreign_key :notes, :roles, column: :creator_id
    add_foreign_key :submissions, :groupings
    add_foreign_key :submission_rules, :assessments
    add_foreign_key :test_groups, :criteria
  end
end
