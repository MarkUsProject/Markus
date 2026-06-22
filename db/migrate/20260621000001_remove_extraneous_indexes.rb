class RemoveExtraneousIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :annotation_categories, name: :index_annotation_categories_on_assessment_id
    remove_index :assignment_files, name: :index_assignment_files_on_assessment_id
    remove_index :criteria, name: :index_criteria_on_assessment_id
    remove_index :exam_templates, name: :index_exam_templates_on_assessment_id
    remove_index :grouping_starter_file_entries, name: :index_grouping_starter_file_entries_on_grouping_id
    remove_index :lti_deployments, name: :index_lti_deployments_on_lti_client_id
    remove_index :lti_line_items, name: :index_lti_line_items_on_lti_deployment_id
    remove_index :lti_services, name: :index_lti_services_on_lti_deployment_id
    remove_index :lti_users, name: :index_lti_users_on_lti_client_id
    remove_index :lti_users, name: :index_lti_users_on_user_id
    remove_index :marks, name: :index_marks_on_result_id
    remove_index :marking_schemes, name: :index_marking_schemes_on_course_id
    remove_index :peer_reviews, name: :index_peer_reviews_on_result_id
    remove_index :roles, name: :index_roles_on_user_id
    remove_index :starter_file_groups, name: :index_starter_file_groups_on_assessment_id
    remove_index :template_divisions, name: :index_template_divisions_on_exam_template_id
    remove_index :test_results, name: :index_test_results_on_test_group_result_id
  end
end
