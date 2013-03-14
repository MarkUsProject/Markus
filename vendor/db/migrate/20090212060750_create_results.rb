class CreateResults < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :results do |t|
      t.integer :submission_id
      t.float :total_mark
      t.string :marking_state
      t.string :overall_comment

      t.timestamps
    end

    foreign_key :results, :submission_id,  :submissions

  end

  def self.down
    drop_table :results
  end
end
