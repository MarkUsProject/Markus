require 'migration_helpers'

class ModifyGroups < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table(:groups, :force => true) do |t|
      t.column  :status,          :string
    end
  end

  def self.down
    drop_table :groups
  end
end
