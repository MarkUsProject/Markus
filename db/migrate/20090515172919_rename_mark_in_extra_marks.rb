class RenameMarkInExtraMarks < ActiveRecord::Migration
  def self.up
    # rename attribute 'mark' in extra_marks
    rename_column :extra_marks, :mark, :extra_mark
  end

  def self.down
    # revert 'extra_marks' name change
    rename_column :extra_marks, :extra_mark, :mark
  end
end
