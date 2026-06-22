class AddUniqueIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :annotation_categories, %i[assessment_id annotation_category_name], unique: true,
                                                                                   name: 'index_annotation_categories_on_assessment_id_and_name'
    add_index :assessments, :parent_assessment_id, unique: true
    add_index :criteria, %i[assessment_id name], unique: true
    add_index :exam_templates, %i[assessment_id name], unique: true
    remove_index :grader_permissions, :role_id
    add_index :grader_permissions, :role_id, unique: true
    add_index :grouping_starter_file_entries, %i[grouping_id starter_file_entry_id], unique: true,
                                                                                      name: 'index_grouping_starter_file_entries_on_grouping_and_entry'
    add_index :lti_clients, %i[host client_id], unique: true
    add_index :lti_deployments, %i[lti_client_id lms_course_id], unique: true
    add_index :lti_users, %i[lti_client_id lti_user_id], unique: true
    add_index :marks, %i[result_id criterion_id], unique: true
    add_index :starter_file_groups, %i[assessment_id name], unique: true
    remove_index :submission_rules, :assessment_id
    add_index :submission_rules, :assessment_id, unique: true
    add_index :template_divisions, %i[exam_template_id label], unique: true
    add_index :test_results, %i[test_group_result_id name], unique: true
    add_index :users, :email, unique: true
    add_index :users, :id_number, unique: true
  end
end
