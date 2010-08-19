require 'migration_helpers'

class CreateTestFile < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :test_files do |t|
      t.column :filename, :string
      t.column :assignment_id, :int
      t.column :filetype, :string
      t.column :is_private, :boolean
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
    add_index :test_files, [:assignment_id, :filename], :name => "index_test_files_on_assignment_id_and_filename", :unique => true
  end

  def self.down
    drop_table :test_files if table_exists?(:test_files)
  end
end
