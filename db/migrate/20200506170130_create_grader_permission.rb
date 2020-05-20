class CreateGraderPermission < ActiveRecord::Migration[6.0]
  def self.up
    create_table :grader_permission do |t|
      t.column :description, :text
      t.column :is_enabled, :boolean
    end
  end

  def self.down
    drop_table :grader_permission
  end
end
