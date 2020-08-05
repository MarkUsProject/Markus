class CreateGraderPermissions < ActiveRecord::Migration[6.0]
  def self.up
    create_table :grader_permissions do |t|
      t.column :user_id, :int, :unique => true
      t.column :manage_extensions, :boolean, :default => false
      t.column :create_delete_annotations, :boolean, :default => false
      t.column :manage_submissions, :boolean, :default => false
      t.column :manage_assessments, :boolean, :default => false
      t.column :run_tests, :boolean, :default => false
      t.column :manage_course_grades, :boolean, :default => false
    end

    add_foreign_key :grader_permissions, :users
  end

  def self.down
    drop_table :grader_permissions
  end
end
