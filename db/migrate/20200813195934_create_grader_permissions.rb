class CreateGraderPermissions < ActiveRecord::Migration[6.0]
  def self.up
    create_table :grader_permissions do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.column :manage_submissions, :boolean, default: false, null: false
      t.column :manage_assessments, :boolean, default: false, null: false
      t.column :run_tests, :boolean, default: false, null: false
    end

  end

  def self.down
    drop_table :grader_permissions
  end
end
