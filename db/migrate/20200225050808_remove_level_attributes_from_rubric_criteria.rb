class RemoveLevelAttributesFromRubricCriteria < ActiveRecord::Migration[6.0]
  def change
    remove_column :rubric_criteria, :level_0_name, :text
    remove_column :rubric_criteria, :level_0_description, :text
    remove_column :rubric_criteria, :level_1_name, :text
    remove_column :rubric_criteria, :level_1_description, :text
    remove_column :rubric_criteria, :level_2_name, :text
    remove_column :rubric_criteria, :level_2_description, :text
    remove_column :rubric_criteria, :level_3_name, :text
    remove_column :rubric_criteria, :level_3_description, :text
    remove_column :rubric_criteria, :level_4_name, :text
    remove_column :rubric_criteria, :level_4_description, :text
  end
end
