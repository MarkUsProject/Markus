class CreateMarks < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :marks do |t|
      t.integer :result_id
      t.integer :criterion_id
      t.integer :mark

      t.timestamps
    end

     foreign_key :marks, :result_id,  :results

  end

  def self.down
    drop_table :marks
  end
end
