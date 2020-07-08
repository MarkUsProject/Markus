class CreateGraderPermissions < ActiveRecord::Migration[6.0]
  def self.up
    create_table :grader_permissions do |t|
      t.column :user_id, :int, :unique => true
      t.column :delete_grace_period_deduction, :boolean, :default => false
      t.column :create_notes, :boolean, :default => false
      t.column :create_delete_annotations, :boolean, :default => false
      t.column :collect_submissions, :boolean, :default => false
      t.column :release_unrelease_grades, :boolean, :default => false
      t.column :manage_grade_entry_forms, :boolean, :default => false
      t.column :manage_assignments, :boolean, :default => false
      t.column :manage_reviewers, :boolean, :default => false
      t.column :manage_exam_templates, :boolean, :default => false
      t.column :run_tests, :boolean, :default => false
      t.column :manage_marking_schemes, :boolean, :default => false
      t.column :download_grades_report, :boolean, :default => false
    end

    add_foreign_key :grader_permissions, :users
  end

  def self.down
    drop_table :grader_permissions
  end
end
