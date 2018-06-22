class RenameInstructorFormGroupsToInvalidOverride < ActiveRecord::Migration[4.2]
  def self.up
      rename_column(:assignments, :instructor_form_groups, :invalid_override)
  end

  def self.down
    rename_column(:assignments, :invalid_override, :instructor_form_groups)
  end
end
