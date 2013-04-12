class AddIsRemarkToAnnotations < ActiveRecord::Migration
  def self.up
    add_column :annotations, :is_remark, :boolean
  end

  def self.down
    remove_column :annotations, :is_remark
  end
end
