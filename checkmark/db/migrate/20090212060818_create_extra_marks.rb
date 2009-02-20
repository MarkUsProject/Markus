class CreateExtraMarks < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :extra_marks do |t|
      t.integer :result_id
      t.string :description
      t.float :mark

      t.timestamps
    end

    foreign_key :extra_marks, :result_id,  :results

  end

  def self.down
    drop_table :extra_marks
  end
end
