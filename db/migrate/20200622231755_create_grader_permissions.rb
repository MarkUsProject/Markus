class CreateGraderPermissions < ActiveRecord::Migration[6.0]
  def self.up
    create_table :grader_permissions do |t|
      t.column :user_id, :int, :unique => true
      t.column :delete_grace_period_deduction, :boolean
      t.column :create_notes, :boolean
      t.column :create_delete_annotations, :boolean
      t.column :collect_submissions, :boolean
      t.column :release_unrelease_grades, :boolean
      t.column :manage_grade_entry_forms, :boolean
      t.column :manage_assignments, :boolean
      t.column :manage_reviewers, :boolean
      t.column :manage_exam_templates, :boolean
      t.column :run_tests, :boolean
      t.column :manage_marking_schemes, :boolean
      t.column :download_grades_report, :boolean
    end

    add_foreign_key :grader_permissions, :users
  end

  def self.down
    drop_table :grader_permissions
  end
end
