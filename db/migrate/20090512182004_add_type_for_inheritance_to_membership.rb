class AddTypeForInheritanceToMembership < ActiveRecord::Migration
  def self.up
    add_column :memberships, :type, :string
  end

  def self.down
    remove_column :memberships, :type
  end
end
