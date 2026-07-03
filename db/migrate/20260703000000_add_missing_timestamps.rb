class AddMissingTimestamps < ActiveRecord::Migration[8.1]
  def change
    add_timestamps :annotations, null: true
    add_timestamps :assessment_section_properties, null: true
    add_timestamps :autotest_settings, null: true
    add_timestamps :grade_entry_students_tas, null: true
    add_timestamps :groupings_tags, null: true
    add_timestamps :grouping_starter_file_entries, null: true
    add_timestamps :grader_permissions, null: true
    add_timestamps :groups, null: true
    add_timestamps :starter_file_groups, null: true
    add_timestamps :section_starter_file_groups, null: true
    add_timestamps :submission_files, null: true
    add_timestamps :starter_file_entries, null: true
    add_column :submissions, :updated_at, :datetime
    add_timestamps :tags, null: true
  end
end
