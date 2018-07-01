class AddTypeForInheritanceToMembership < ActiveRecord::Migration[4.2]
  def self.up
    add_column :memberships, :type, :string
  end

  def self.down
    remove_column :memberships, :type
  end
end
