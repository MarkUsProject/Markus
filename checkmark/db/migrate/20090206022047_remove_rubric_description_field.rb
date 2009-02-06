class RemoveRubricDescriptionField < ActiveRecord::Migration
  def self.up
    remove_column :rubric_criterias, :description
  end

  def self.down
    add_column :rubric_criterias, :description, :text
  end
end
