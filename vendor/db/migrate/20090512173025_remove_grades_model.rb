class RemoveGradesModel < ActiveRecord::Migration
  def self.up
    drop_table :grades
  end

  def self.down
    create_table :grades do |t|
      t.column :user_id,        :int
      t.column :group_id,       :int
      t.column :assignment_id,  :int
      t.column :grade,          :int
      t.timestamps
    end
  end
end
