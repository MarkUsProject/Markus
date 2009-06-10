class AddReleasedColumnToResults < ActiveRecord::Migration
  def self.up
    add_column :results, :released_to_students, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :results, :released_to_students
  end
end
