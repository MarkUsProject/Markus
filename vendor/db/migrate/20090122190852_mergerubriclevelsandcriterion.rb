class Mergerubriclevelsandcriterion < ActiveRecord::Migration
  def self.up
    add_column :rubric_criteria, :level_0_name, :text
    add_column :rubric_criteria, :level_0_description, :text
    add_column :rubric_criteria, :level_1_name, :text
    add_column :rubric_criteria, :level_1_description, :text
    add_column :rubric_criteria, :level_2_name, :text
    add_column :rubric_criteria, :level_2_description, :text
    add_column :rubric_criteria, :level_3_name, :text
    add_column :rubric_criteria, :level_3_description, :text
    add_column :rubric_criteria, :level_4_name, :text
    add_column :rubric_criteria, :level_4_description, :text
  end

  def self.down
    remove_column :rubric_criteria, :level_0_name
    remove_column :rubric_criteria, :level_0_description
    remove_column :rubric_criteria, :level_1_name
    remove_column :rubric_criteria, :level_1_description
    remove_column :rubric_criteria, :level_2_name
    remove_column :rubric_criteria, :level_2_description
    remove_column :rubric_criteria, :level_3_name
    remove_column :rubric_criteria, :level_3_description
    remove_column :rubric_criteria, :level_4_name
    remove_column :rubric_criteria, :level_4_description
  end
end
