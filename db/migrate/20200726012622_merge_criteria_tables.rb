class MergeCriteriaTables < ActiveRecord::Migration[6.0]
  def change
    # Create new criteria table
    create_table :criteria do |t|
      t.string 'name', null: false
      t.string 'type', null: false
      t.text 'description', null: false, default: ''
      t.integer 'position', null: false
      t.decimal 'max_mark', precision: 10, scale: 1, null: false
      t.integer 'assigned_groups_count', default: 0, null: false
      t.boolean 'ta_visible', default: true, null: false
      t.boolean 'peer_visible', default: false, null: false
      t.timestamps null: false

      t.references :assessment, null: false, index: true, foreign_key: true
    end

    # Update/remove references to criteria in other tables
    remove_column :assessments, :checkbox_criteria_count, :integer
    remove_column :assessments, :flexible_criteria_count, :integer
    remove_column :assessments, :rubric_criteria_count, :integer
    remove_column :criteria_assignment_files_joins, :criterion_type, :string, null: false
    remove_column :criterion_ta_associations, :criterion_type, :string

    remove_column :test_groups, :criterion_type, :string
    add_index :test_groups, :criterion_id

    remove_foreign_key :levels, :rubric_criteria
    rename_column :levels, :rubric_criterion_id, :criterion_id
    add_foreign_key :levels, :criteria

    remove_foreign_key :annotation_categories, :flexible_criteria
    add_foreign_key :annotation_categories, :criteria, column: :flexible_criterion_id

    remove_index :marks, column: [:markable_id, :result_id, :markable_type], name: "marks_u1", unique: true
    remove_column :marks, :markable_type, :string
    rename_column :marks, :markable_id, :criterion_id
    add_foreign_key :marks, :criteria

    # Remove old tables
    drop_table :checkbox_criteria, cascade: :force do |t|
      t.string "name", null: false
      t.text "description"
      t.integer "position"
      t.decimal "max_mark", precision: 10, scale: 1, null: false
      t.timestamps
      t.integer "assigned_groups_count", default: 0
      t.boolean "ta_visible", default: true, null: false
      t.boolean "peer_visible", default: false, null: false
      t.bigint "assessment_id", null: false
      t.index ["assessment_id", "name"], name: "index_flexible_criteria_on_assessment_id_and_name", unique: true
      t.index ["assessment_id"], name: "index_flexible_criteria_on_assessment_id"
    end

    drop_table :flexible_criteria, cascade: :force do |t|
      t.string "name", null: false
      t.text "description"
      t.integer "position"
      t.decimal "max_mark", precision: 10, scale: 1, null: false
      t.timestamps
      t.integer "assigned_groups_count", default: 0
      t.boolean "ta_visible", default: true, null: false
      t.boolean "peer_visible", default: false, null: false
      t.bigint "assessment_id", null: false
      t.index ["assessment_id", "name"], name: "index_checkbox_criteria_on_assessment_id_and_name", unique: true
      t.index ["assessment_id"], name: "index_checkbox_criteria_on_assessment_id"
    end

    drop_table :rubric_criteria, cascade: :force do |t|
      t.string "name", null: false
      t.integer "position"
      t.decimal "max_mark", precision: 10, scale: 1, null: false
      t.timestamps
      t.integer "assigned_groups_count", default: 0
      t.boolean "ta_visible", default: true, null: false
      t.boolean "peer_visible", default: false, null: false
      t.bigint "assessment_id", null: false
      t.index ["assessment_id", "name"], name: "index_rubric_criteria_on_assessment_id_and_name", unique: true
      t.index ["assessment_id"], name: "rubric_criteria_index_1"
    end
  end
end
