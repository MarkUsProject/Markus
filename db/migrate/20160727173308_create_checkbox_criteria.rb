class CreateCheckboxCriteria < ActiveRecord::Migration
  def change
    create_table :checkbox_criteria do |t|
      t.string :name, null: false
      t.string :description
      t.integer :position
      t.references :assignment, null: false, foreign_key: true
      t.decimal :max_mark, precision: 10, scale: 1
      t.integer :assigned_groups_count, default: 0
      t.boolean :ta_visible, null: false, default: true
      t.boolean :peer_visible, null: false, default: false
      t.timestamps null: false
    end
    add_index :checkbox_criteria, [:assignment_id, :name], unique: true, name: 'index_checkbox_criteria_on_assignment_id_and_name'
  end
end
