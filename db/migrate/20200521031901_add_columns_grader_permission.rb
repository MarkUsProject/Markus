class AddColumnsGraderPermission < ActiveRecord::Migration[6.0]
  def change
    add_column :grader_permission, :manage_reviewers, :boolean
    add_column :grader_permission, :manage_exam_templates, :boolean
    add_column :grader_permission, :run_tests, :boolean
    add_column :grader_permission, :manage_marking_schemes, :boolean
  end
end
