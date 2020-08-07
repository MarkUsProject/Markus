class CreateStarterFileTables < ActiveRecord::Migration[6.0]
  def change
    create_table :starter_file_groups do |t|
      t.references :assessment, null: false, foreign_key: true
      t.string :entry_rename, null: false, default: ''
      t.boolean :use_rename, null: false, default: false
      t.string :name, null: false
    end

    create_table :starter_file_entries do |t|
      t.references :starter_file_group, null: false, foreign_key: true
      t.string :path, null: false
    end

    create_table :section_starter_file_groups do |t|
      t.references :section, null: false, foreign_key: true
      t.references :starter_file_group, null: false, foreign_key: true
    end

    create_table :grouping_starter_file_entries do |t|
      t.references :grouping, null: false, foreign_key: true
      t.references :starter_file_entry, null: false, foreign_key: true
    end

    add_column :assignment_properties, :starter_file_type, :string, null: false, default: :simple
    add_column :assignment_properties, :starter_file_updated_at, :datetime
    add_reference :assignment_properties, :default_starter_file_group
    add_foreign_key :assignment_properties, :starter_file_groups, column: :default_starter_file_group_id
    remove_column :groupings, :starter_code_revision_identifier, :text
    add_column :groupings, :starter_file_timestamp, :datetime
    add_column :groupings, :starter_file_changed, :boolean, null: false, default: false
  end
end
