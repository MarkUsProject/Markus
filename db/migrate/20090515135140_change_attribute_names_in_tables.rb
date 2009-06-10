class ChangeAttributeNamesInTables < ActiveRecord::Migration
  def self.up
    # rename attribute 'name' in rubric_criteria to 'rubric_criterion_name'
    rename_column :rubric_criteria, :name, :rubric_criterion_name
    # rename attribute 'name' in annotation_categories to 'annotation_category_name'
    rename_column :annotation_categories, :name, :annotation_category_name
    # rename attribute 'name' in groups to 'group_name'
    rename_column :groups, :name, :group_name
    # rename attribute 'status' in submission_files
    rename_column :submission_files, :status, :submission_file_status
    # rename attribute 'status' in memberships
    rename_column :memberships, :status, :membership_status
  end

  def self.down
    # revert 'rubric_criterion_name' name change
    rename_column :rubric_criteria, :rubric_criterion_name, :name
    # revert 'annotation_category_name' name change
    rename_column :annotation_categories, :annotation_category_name, :name
    # revert 'group_name' name change
    rename_column :groups, :group_name, :name
    # revert 'submission_file_status' name change
    rename_column :submission_files, :submission_file_status, :status
    # revert 'submission_file_status' name change
    rename_column :memberships, :membership_status, :status
  end
end
