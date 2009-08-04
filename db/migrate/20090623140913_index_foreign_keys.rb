class IndexForeignKeys < ActiveRecord::Migration
  def self.up
    add_index :annotation_categories, :assignment_id
    add_index :annotation_texts, :annotation_category_id
    #add_index :annotations, :annotation_text_id
    add_index :marks, :result_id
    add_index :marks, :rubric_criterion_id
    add_index :extra_marks, :result_id
    add_index :memberships, :user_id
    add_index :memberships, :grouping_id
    add_index :submission_files, :user_id
    add_index :rubric_criteria, :assignment_id
    add_index :submissions, :grouping_id
    add_index :groupings, :group_id
    add_index :groupings, :assignment_id
    add_index :submission_rules, :assignment_id
    add_index :assignment_files, :assignment_id

  end

  def self.down
    remove_index :annotation_categories, :assignment_id
    remove_index :annotation_texts, :annotation_category_id
    remove_index :annotations, :annotation_text_id
    remove_index :marks, :result_id
    remove_index :marks, :rubric_criterion_id
    remove_index :extra_marks, :result_id
    remove_index :memberships, :user_id
    remove_index :memberships, :grouping_id
    remove_index :submission_files, :user_id
    remove_index :rubric_criteria, :assignment_id
    remove_index :submissions, :grouping_id
    remove_index :groupings, :group_id
    remove_index :groupings, :assignment_id
    remove_index :submission_rules, :assignment_id
    remove_index :assignment_files, :assignment_id
  end
end
