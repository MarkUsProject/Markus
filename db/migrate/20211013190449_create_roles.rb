class CreateRoles < ActiveRecord::Migration[6.1]
  def change
    create_table :roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :section, null: true, foreign_key:true
      t.string :type
      t.boolean :hidden
      t.integer :grace_credits, default: 0
      t.boolean :receives_results_emails, null: false, default: false
      t.boolean :receives_invite_emails, null: false, default: false

      t.timestamps
    end
  end
end
