class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.column  :name,          :string,  :null => false
      t.column  :description,   :string
      t.column  :message,       :text
      t.column  :due_date,      :datetime
      t.column  :group_min,     :integer, :null => false, :default => 1
      t.column  :group_max,     :integer, :null => false, :default => 1
      
      t.timestamps
    end
    
    add_index :assignments, :name, :unique => true
  end

  def self.down
    drop_table :assignments
  end
end