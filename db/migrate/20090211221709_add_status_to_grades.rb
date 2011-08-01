class AddStatusToGrades < ActiveRecord::Migration

  def self.up
    add_column :grades, :status, :string
  end

  def self.down
    remove_column :grades, :status
  end

end
