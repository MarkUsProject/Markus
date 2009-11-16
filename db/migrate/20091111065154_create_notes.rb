class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.string :message, :null => false
      t.integer :creator_id, :null => false
      t.integer :grouping_id, :null => false
      t.text :type, :null => false

      t.timestamps
    end
    add_index :notes, :grouping_id
    add_index :notes, :creator_id
 end
  

  def self.down
    remove_index :notes, :grouping_id
    remove_index :notes, :creator_id 
    drop_table :notes
  end
end
