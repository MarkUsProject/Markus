class AddStatusToGrades < ActiveRecord::Migration[4.2]

  def self.up
    add_column :grades, :status, :string
  end

  def self.down
    remove_column :grades, :status
  end

end
