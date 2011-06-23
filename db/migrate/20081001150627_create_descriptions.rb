require 'migration_helpers'

class CreateDescriptions < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up

      create_table :descriptions do |t|
        t.column    :name,            :text
        t.column    :description,     :text
        t.column    :token,           :text
        t.column    :ntoken,          :int
        t.column    :category_id,     :int
        t.column    :assignment_id,   :int
      end

      add_index :descriptions, [:category_id]
      add_index :descriptions, [:assignment_id]

      foreign_key_no_delete :descriptions, :category_id, :categories
      foreign_key_no_delete :descriptions, :assignment_id, :assignments

  end

  def self.down
    drop_table :descriptions
  end
end
