class AddReleasedColumnToResults < ActiveRecord::Migration[4.2]
  def self.up
    add_column :results, :released_to_students, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :results, :released_to_students
  end
end
