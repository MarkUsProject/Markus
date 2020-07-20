class CreateStarterCodeTables < ActiveRecord::Migration[6.0]
  def change
    create_table :starter_code_groups do |t|
      t.references :assessment, null: false, foreign_key: true
      t.boolean :is_default, null: false, default: false
      t.string :entry_rename, null: false, default: ''
      t.boolean :use_rename, null: false, default: false
      t.string :name, null: false
    end

    create_table :starter_code_entries do |t|
      t.references :starter_code_group, null: false, foreign_key: true
      t.string :path, null: false
    end

    create_table :section_starter_code_groups do |t|
      t.references :section, null: false, foreign_key: true
      t.references :starter_code_group, null: false, foreign_key: true
    end

    add_column :assignment_properties, :starter_code_type, :string, null: false, default: :simple
  end
end
