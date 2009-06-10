class CreateGrades < ActiveRecord::Migration
  
  def self.up
    create_table :grades do |t|
      t.column :user_id,        :int
      t.column :group_id,       :int
      t.column :assignment_id,  :int
      t.column :grade,          :int
      t.timestamps
    end
  end

  def self.down
    drop_table :grades
  end
    
end
