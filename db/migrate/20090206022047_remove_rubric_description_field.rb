class RemoveRubricDescriptionField < ActiveRecord::Migration
  def self.up
    remove_column :rubric_criteria, :description
  end

  def self.down
    add_column :rubric_criteria, :description, :text
  end
end
