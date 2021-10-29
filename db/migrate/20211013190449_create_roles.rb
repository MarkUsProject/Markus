class CreateRoles < ActiveRecord::Migration[6.1]
  def change
    create_table :roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :section, null: true, foreign_key:true
      t.string :type, null: false
      t.boolean :hidden, null: false, default: false
      t.integer :grace_credits, null: false, default: 0
      t.boolean :receives_results_emails, null: false, default: false
      t.boolean :receives_invite_emails, null: false, default: false

      t.timestamps
    end
    remove_column :users, :grace_credits, :integer
    remove_column :users, :hidden, :boolean
    remove_column :users, :section_id, :integer
    remove_column :users, :receives_results_emails, :boolean
    remove_column :users, :receives_invite_emails, :boolean

    add_reference :grader_permissions, :role, foreign_key: true
    remove_reference :grader_permissions, :user, type: :integer

    add_reference :grade_entry_students, :role, foreign_key:true
    remove_reference :grade_entry_students, :user

    add_reference :memberships, :role, foreign_key: true
    remove_reference :memberships, :user, foreign_key: true

    add_reference :test_runs, :role, foreign_key: true
    remove_reference :test_runs, :user, foreign_key: true

    remove_reference :tags, :user, foreign_key: true
    add_reference :tags, :role, foreign_key: true

    remove_reference :split_pdf_logs, :user, foreign_key: true
    add_reference :split_pdf_logs, :role, foreign_key: true
  end
end
